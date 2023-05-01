import PALEOboxes as PB
import PALEOmodel
using Plots

include(joinpath(@__DIR__, "../reservoirs/reactions_ex5.jl"))

#####################################################
# Create model
#######################################################

model = PB.create_model_from_config(
    joinpath(@__DIR__, "config_ex5_flux_noisotope.yaml"),
    "example5_flux_noisotope"
)

#########################################################
# Initialize
##########################################################

initial_state, modeldata = PALEOmodel.initialize!(model)

#####################################################################
# Optional: call ODE function to check derivative
#######################################################################

# create a Run object to hold model and output
paleorun = PALEOmodel.Run(model=model, output = PALEOmodel.OutputWriters.OutputMemory())

initial_deriv = similar(initial_state)
PALEOmodel.ODE.ModelODE(modeldata)(initial_deriv, initial_state , nothing, 0.0)
println("initial_state: ", initial_state)
println("initial_deriv: ", initial_deriv)

#################################################################
# Integrate vs time
##################################################################
println("integrate, ODE")
# first run is slow as it includes JIT time
@time PALEOmodel.ODE.integrate(
    paleorun, initial_state, modeldata, (0.0, 10.0), 
    solvekwargs=(
        reltol=1e-5,
        # saveat=0.1, # save output every 0.1 yr see https://diffeq.sciml.ai/dev/basics/common_solver_opts/
    )
);
   
############################
# Table of output
###########################

# vscodedisplay(
#     PB.get_table(paleorun.output, ["Box1.A", "Box2.B", "global.E_total", "Box1.decay_flux", "fluxBoxes.flux_B"]),
#     "Example 5"
# )

########################################
# Plot output
########################################

display(plot(paleorun.output, ["Box1.A", "Box2.B", "global.E_total"]; ylabel="reservoir (mol)"))
display(plot(paleorun.output, ["Box1.decay_flux", "fluxBoxes.flux_B"]; ylabel="flux (mol yr-1)"))
display(plot(paleorun.output, ["Box1.A_delta", "Box1.decay_flux.v_delta", "Box2.B_delta", "global.E_total.v_delta", ]; ylabel="delta (per mil)"))