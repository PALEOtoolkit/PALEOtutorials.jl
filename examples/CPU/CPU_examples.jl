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
# run = CPU_expts([], comparedata)

# LIP CO2 input
run = CPU_expts([("LIP", 3e18)])

# increase E
# run = CPU_expts([("E", 2.0)])
# increase V
# run = CPU_expts([("V", 2.0)])

initial_state, modeldata = PALEOmodel.initialize!(run)

# call ODE function to check derivative
initial_deriv = similar(initial_state)
PALEOmodel.ODE.ModelODE(modeldata)(initial_deriv, initial_state , nothing, 0.0)
println("initial_state", initial_state)
println("initial_deriv", initial_deriv)


println("integrate, ODE")
# first run is slow as it includes JIT time
@time PALEOmodel.ODE.integrate(
    run, initial_state, modeldata, (0.0, 1e6), 
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
pager=PALEOmodel.PlotPager(6, (legend_background_color=nothing, ))

plot_CPU(run.output; pager=pager)


@info "End $(@__FILE__)"
