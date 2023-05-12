import PALEOboxes as PB
import PALEOmodel

import PALEOocean
using Plots

include(joinpath(@__DIR__, "reactions_Alk_pH.jl")) # @__DIR__ so still runs when building docs


#####################################################
# Create model

model = PB.create_model_from_config(joinpath(@__DIR__, "config_ex1.yaml"), "Minimal_Alk_pH")

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
paleorun = PALEOmodel.Run(model=model, output = PALEOmodel.OutputWriters.OutputMemory())

println("integrate, DAE")
# first run is slow as it includes JIT time
@time PALEOmodel.ODE.integrateDAE(
    paleorun, initial_state, modeldata, (0.0, 200.0), 
    solvekwargs=(
        reltol=1e-6,
        # saveat=0.1, # save output every 0.1 yr see https://diffeq.sciml.ai/dev/basics/common_solver_opts/
    )
);
   
########################################
# Plot output
########################################

display(plot(paleorun.output, ["ocean.TAlk_conc", "ocean.DIC_conc"],                                           (cell=1,);
    ylabel="TAlk, DIC conc (mol m-3)"))
# display(plot(paleorun.output, ["ocean.TAlk","ocean.TAlk_sms"],                                                 (cell=1,)))
display(plot(paleorun.output, "ocean.pH",                                                                      (cell=1,)))
display(plot(paleorun.output, ["ocean.DIC_conc", "ocean.HCO3_conc", "ocean.CO3_conc", "ocean.CO2_aq_conc"],    (cell=1,);
    ylabel="DIC species (mol m-3)"))
# display(plot(paleorun.output, "ocean.DIC",                                                                     xlims=(0, 150.0),  (cell=1,)))
