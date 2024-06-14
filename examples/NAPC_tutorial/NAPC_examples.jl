using Logging
# using DiffEqBase
using OrdinaryDiffEq
using Sundials
# using BenchmarkTools
using Plots

@info "Start $(@__FILE__)"

@info "importing modules ... (may take a few seconds)"
import PALEOboxes as PB
# import PALEOreactions
import PALEOocean
using PALEOmodel
@info "                  ... done"

global_logger(ConsoleLogger(stderr,Logging.Info))

include("NAPC_expts.jl")
include("NAPC_reactions.jl")

run = NPZ_shelf_expts("P_O2", ["baseline"]); tspan=(0,5.0)

initial_state, modeldata = PALEOmodel.initialize!(run)

# Check initial derivative:
# initial_deriv = similar(initial_state)
# PALEOmodel.ODE.ModelODE(modeldata)(initial_deriv, initial_state , (run=run, modeldata=modeldata), 0.0)
# Check Jacobian:
# jac, jac_prototype = PALEOmodel.JacobianAD.jac_config_ode(:ForwardDiffSparse, run.model, initial_state, modeldata, 0.0)
# J = copy(jac_prototype)
# jac(jac_prototype, initial_state, nothing, 0.0)

# first run includes JIT time
sol = PALEOmodel.ODE.integrateForwardDiff(
    run, initial_state, modeldata, tspan,
    solvekwargs=(saveat=1/8760, reltol=1e-5, maxiters=1000000),
)  
   
########################################
# Plot output
########################################

colT=collect(range(start=tspan[1], stop=tspan[end], step=0.5))

# individual plots
#plotlyjs(size=(500, 300))
#pager = PALEOmodel.DefaultPlotPager()

# assemble plots onto screens with 6 subplots
gr(size=(1600, 800)) # gr backend (plotly merges captions with multiple panels)
pager=PALEOmodel.PlotPager((2, 3), (legend_background_color=nothing, ))

pager(plot(title="Total P", run.output, "global.total_P"))
pager(plot(title="Total O2", run.output, "global.total_O2"))
pager(:newpage) # flush output

pager(heatmap(title="O2", run.output, "ocean.O2", (column=1, ), clim=(0,Inf)))
pager(heatmap(title="P", run.output, "ocean.P", (column=1, ), clim=(0,Inf)))

pager(heatmap(title="P0", run.output, "ocean.P0", (column=1, ), clim=(0,Inf)))
pager(heatmap(title="P0_growth", run.output, "ocean.P0_growth_rate", (column=1, ), clim=(0,Inf)))
pager(:newpage) # flush output

# pager(heatmap(title="Z0", run.output, "ocean.Z0", (column=1, ), clim=(0,Inf)))
# pager(:newpage) # flush output

# pager(heatmap(title="Z0_growth", run.output, "ocean.Z0_growth_rate", (column=1, ), clim=(0,Inf)))
# pager(:newpage) # flush output

@info "End $(@__FILE__)"
