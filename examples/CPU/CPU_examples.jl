using Logging
using DataFrames
using Plots

global_logger(ConsoleLogger(stderr,Logging.Info))

@info "Start $(@__FILE__)"

@info "importing modules ... (may take a few seconds)"
import PALEOboxes as PB
import PALEOmodel
import PALEOcopse
@info "                  ... done"

include("CPU_reactions.jl")
include("CPU_expts.jl")


# baseline steady-state
model = PB.create_model_from_config(
    joinpath(@__DIR__, "CPU_cfg.yaml"), 
    "CPU_Zhang2020"; 
    modelpars=Dict(), # optional Dict can be supplied to set top-level (model wide) Parameters
)
        

# LIP CO2 input
CPU_expts(model, [("LIP", 3e18)])

# increase E
# CPU_expts(model, [("E", 2.0)])
# increase V
# CPU_expts(model, [("V", 2.0)])

initial_state, modeldata = PALEOmodel.initialize!(model)

# call ODE function to check derivative
initial_deriv = similar(initial_state)
PALEOmodel.ODE.ModelODE(modeldata)(initial_deriv, initial_state , nothing, 0.0)
println("initial_state", initial_state)
println("initial_deriv", initial_deriv)

paleorun = PALEOmodel.Run(model=model, output = PALEOmodel.OutputWriters.OutputMemory())

println("integrate, ODE")
# first run is slow as it includes JIT time
@time PALEOmodel.ODE.integrate(
    paleorun, initial_state, modeldata, (0.0, 1e6), 
    solvekwargs=(
        reltol=1e-5,
        # saveat=1e6, # save output every 1e6 yr see https://diffeq.sciml.ai/dev/basics/common_solver_opts/
    )
)  
   
########################################
# Plot output
########################################

# individual plots
# plotlyjs(size=(750, 500)) # plotlyjs backend
# pager = PALEOmodel.DefaultPlotPager()

# assemble plots onto screens with 6 subplots
gr(size=(1200, 900)) # gr backend (plotly merges captions with multiple panels)
pager=PALEOmodel.PlotPager(6, (legend_background_color=nothing, margin=(5, :mm)))

plot_CPU(paleorun.output; pager=pager)


@info "End $(@__FILE__)"
