import PALEOboxes as PB
import PALEOmodel
import PALEOcopse
using Plots
import PALEOreactions

include("reactions_ex6_Alk_pH.jl")
include("reactions_ex6_AirSeaExchange.jl")                                                        
#####################################################
# Create model

model = PB.create_model_from_config(joinpath(@__DIR__, "config_ex6.yaml"), "Minimal_Alk_pH")

#########################################################
# Initialize
##########################################################

initial_state, modeldata = PALEOmodel.initialize!(model)

#####################################################################
# Optional: call ODE function to check derivative
#######################################################################
initial_deriv = similar(initial_state)
PALEOmodel.ODE.ModelODE(modeldata)(initial_deriv, initial_state , nothing, 0.0)
println("initial_state: ", initial_state)
println("initial_deriv: ", initial_deriv)

#################################################################
# Integrate vs time
##################################################################

# create a Run object to hold model and output
run = PALEOmodel.Run(model=model, output = PALEOmodel.OutputWriters.OutputMemory())

println("integrate, DAE")
# first run is slow as it includes JIT time
@time PALEOmodel.ODE.integrateDAE(
    run, initial_state, modeldata, (0.0, 150.0), 
    solvekwargs=(
        reltol=1e-6,
        # saveat=0.1, # save output every 0.1 yr see https://diffeq.sciml.ai/dev/basics/common_solver_opts/
    )
);
   
########################################
# Plot output
########################################

display(plot(run.output, "ocean.TA_conc",                                                                 xlims=(0, 150.0),            (cell=1,)))
display(plot(run.output, ["ocean.TA","ocean.TA_sms"],                                                     xlims=(0, 150.0),            (cell=1,)))
display(plot(run.output, ["ocean.DIC_conc", "ocean.HCO3_conc", "ocean.CO3_conc", "ocean.CO2_aq_conc"],    xlims=(0, 150.0),            (cell=1,)))
display(plot(run.output, "ocean.pH",                                                                      xlims=(0, 150.0),            (cell=1,)))
display(plot(run.output, "atm.CO2",                                                                       xlims=(0, 150.0),                     ))  
display(plot(run.output, "atm.CO2_sms",                                                                   xlims=(0, 150.0),                     ))
display(plot(run.output, "fluxAtmtoOceansurface.flux_CO2",                                                xlims=(0, 150.0),            (cell=1,)))
display(plot(run.output, "ocean.DIC",                                                                     xlims=(0, 150.0),            (cell=1,)))
display(plot(run.output, "atm.CO2",                                                                       xlims=(0, 150.0),                     ))
display(plot(run.output, "global.C_total",                                                                xlims=(0, 150.0),                     ))
