import PALEOboxes as PB
import PALEOmodel
using Plots

include(joinpath(@__DIR__, "../reservoirs/reactions_ex5.jl"))

#####################################################
# Create model
#######################################################

model = PB.create_model_from_config(
    joinpath(@__DIR__, "../reservoirs/config_ex5.yaml"),
    "example5"
)


#########################################################
# Initialize
##########################################################

initial_state, modeldata = PALEOmodel.initialize!(model)

tspan = (0.0, 10.0)
dt = 0.5

# get nested NamedTuples with data arrays for every Variable in the model
all_vars = PB.VariableAggregatorNamed(modeldata)
all_values = all_vars.values # nested NamedTuples 

# create an object to hold output
output_euler = PALEOmodel.OutputWriters.OutputMemory()
nsteps = floor(Int, (tspan[2] - tspan[1])/dt)
PALEOmodel.OutputWriters.initialize!(output_euler, model, modeldata, nsteps+1; rec_coord=:tmodel)

#################################################################
# Integrate vs time
##################################################################
println("integrate, using first-order explicit Euler 'by hand'")

# set initial time
tmodel = tspan[1]
# step number
n = 0

# loop over time steps, taking a zero last timestep to save output
while tmodel <= tspan[2] && n <= nsteps
    # calculate time derivative (_sms Variables)
    PB.do_deriv(modeldata.dispatchlists_all)

    # add record to output
    PALEOmodel.OutputWriters.add_record!(output_euler, model, modeldata, tmodel)

    # account for a short (or zero) last timestep
    global dt_actual = min(dt, tspan[2] - tmodel)

    # naive first order explicit Euler for our two state Variables
    # (advances state variable from tmodel -> tmodel + dt)
    all_values.Box1.A .+= dt_actual .* all_values.Box1.A_sms
    all_values.Box2.B .+= dt_actual .* all_values.Box2.B_sms

    global tmodel += dt_actual  # update tmodel to time we have now stepped to
    global n += 1
end

############################
# Table of output
###########################

# vscodedisplay(
#     PB.get_table(output_euler, ["Box1.A", "Box2.B", "global.E_total", "Box1.decay_flux", "fluxBoxes.flux_B"]),
#     "Example 5"
# )

########################################
# Plot output
########################################

display(plot(output_euler, ["Box1.A", "Box2.B", "global.E_total"]; ylabel="reservoir (mol)"))
display(plot(output_euler, ["Box1.A.v_moldelta", "Box2.B.v_moldelta", "global.E_total.v_moldelta"]; ylabel="reservoir (mol * delta)"))
display(plot(output_euler, ["Box1.decay_flux", "fluxBoxes.flux_B"]; ylabel="flux (mol yr-1)"))
display(plot(output_euler, ["Box1.A_delta", "Box1.decay_flux.v_delta", "Box2.B_delta", "global.E_total.v_delta", ]; ylim=(-20, 100), ylabel="delta (per mil)"))