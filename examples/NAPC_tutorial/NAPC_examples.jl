using Logging
using OrdinaryDiffEq
using Sundials
using Plots

@info "Start $(@__FILE__)"

@info "importing modules ... (may take a few seconds)"
import PALEOboxes as PB
import PALEOocean
using PALEOmodel
@info "                  ... done"

global_logger(ConsoleLogger(stderr,Logging.Info))

# include("NAPC_expts.jl")
include("NAPC_reactions.jl")
include("atmreservoirreaction.jl") # for ReactionReservoirAtm

transport_dir = "S2P3_transport_20240614" # folder containing S2P3 physical variables output collated to netcdf files

# P, O2 only population-based phytoplankton model
model = PB.create_model_from_config(
    joinpath(@__DIR__, "NAPC_cfg.yaml"),
    "NP_shelf";
    modelpars=Dict(
        "phys_file"=>joinpath(transport_dir, "S2P3_depth80_m2amp04_phys.nc"),
        "surf_file"=>joinpath(transport_dir, "S2P3_depth80_m2amp04_surf.nc"),
    )
)

tspan=(0,5.0)

initial_state, modeldata = PALEOmodel.initialize!(model)

paleorun = PALEOmodel.Run(model=model, output = PALEOmodel.OutputWriters.OutputMemory()) 

# first run includes JIT time
sol = PALEOmodel.ODE.integrateForwardDiff(
    paleorun, initial_state, modeldata, tspan,
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
pager=PALEOmodel.PlotPager((2, 3), (legend_background_color=nothing, margin=(5, :mm)))

pager(plot(title="Total P", paleorun.output, "global.total_P"))
pager(plot(title="Total O2", paleorun.output, "global.total_O2"))
pager(:newpage) # flush output

pager(heatmap(title="O2", paleorun.output, "ocean.O2", (column=1, ), clim=(0,Inf)))
pager(heatmap(title="P", paleorun.output, "ocean.P", (column=1, ), clim=(0,Inf)))

pager(heatmap(title="P0", paleorun.output, "ocean.P0", (column=1, ), clim=(0,Inf)))
pager(heatmap(title="P0_growth", paleorun.output, "ocean.P0_growth_rate", (column=1, ), clim=(0,Inf)))
pager(:newpage) # flush output

@info "End $(@__FILE__)"
