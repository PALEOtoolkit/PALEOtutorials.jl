import PALEOboxes as PB
import PALEOmodel
using Plots

include(joinpath(@__DIR__, "reactions_ex3.jl"))

#####################################################
# Create model
#######################################################

model = PB.create_model_from_config(joinpath(@__DIR__, "config_ex3.yaml"), "example3")

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

println("integrate, ODE")
# first run is slow as it includes JIT time
@time PALEOmodel.ODE.integrate(
    paleorun, initial_state, modeldata, (0.0, 10.0), 
    solvekwargs=(
        reltol=1e-5,
        # saveat=0.1, # save output every 0.1 yr see https://diffeq.sciml.ai/dev/basics/common_solver_opts/
    )
);
   
########################################
# Plot output
########################################

display(plot(paleorun.output, ["global.A", "global.B"]; ylabel="reservoir (mol)"))
display(plot(paleorun.output, "global.decay_flux"))