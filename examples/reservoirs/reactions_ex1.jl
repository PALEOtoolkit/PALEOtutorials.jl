module Example1

import PALEOboxes as PB

"""
    ReactionExample1

Minimal but verbose example with a single state variable, first order decay.

This uses only low-level operations in order to provide a standalone example
that demonstrates all the steps needed for a functioning PALEO model.

See Example 2 for how to implement this functionality with much less boilerplate code.
"""
Base.@kwdef mutable struct ReactionExample1{P} <: PB.AbstractReaction
    base::PB.ReactionBase

    pars::P = PB.ParametersTuple(
        PB.ParDouble("kappa",   1.0, units="yr-1", description="first order decay constant"),
    )

end

function PB.register_methods!(rj::ReactionExample1)
    # Variables are labelled as state Variables and derivatives by setting the 
    # :vfunction attribute to VF_StateExplicit and VF_Deriv.
    # also need to set :field_data
    A = PB.VarDepScalar("A",            "mol",      "reservoir for species A",
                    attributes=(:vfunction=>PB.VF_StateExplicit, :field_data=>PB.ScalarData))
    A_sms = PB.VarContribScalar("A_sms",    "mol yr-1", "reservoir A source - sink",
                    attributes=(:vfunction=>PB.VF_Deriv, :field_data=>PB.ScalarData))
    # Provide a Property decay_flux as diagnostic output
    decay_flux = PB.VarPropScalar("decay_flux",  "mol yr-1", "decay flux from reservoir A")

    PB.add_method_setup!(rj, setup_example1, (PB.VarList_namedtuple([A]),) )

    PB.add_method_initialize!(rj, initialize_example1, (PB.VarList_namedtuple([A_sms]),) )

    PB.add_method_do!(rj, do_example1,  (PB.VarList_namedtuple([A, A_sms, decay_flux]), ) )

    return nothing
end

# setup method, called at model startup
# NB: this is called three times, with attribute_name indicating the action or value that should be set:
#   :setup - any non-state-Variable initialisation (not used here)
#   :norm_value - Variable normalisation, usually read from the :norm_value Variable attribute
#   :initial_value - Variable initial value, usually read from the :initial_value attribute
function setup_example1(m::PB.ReactionMethod, (varsdata, ), cellrange::PB.AbstractCellRange, attribute_name)

    attribute_name in (:norm_value, :initial_value) || return

    var_A = PB.get_variable(m, "A")  # get the Variable as supplied to add_method_setup! 
    value = PB.get_attribute(var_A, attribute_name) # read attribute 
    @info "setup_example1: setting A[] to $value read from from attribute $attribute_name"
    varsdata.A[] = value

    return nothing
end

# initialize method, called at start of each main loop timestep
function initialize_example1(m::PB.ReactionMethod, (varsdata, ), cellrange::PB.AbstractCellRange, _)

    varsdata.A_sms[] = 0.0

    return nothing
end

# do method, called each main loop timestep
function do_example1(m::PB.ReactionMethod, pars, (varsdata, ), cellrange::PB.AbstractCellRange, deltat)
    rj = m.reaction

    # mol yr-1                yr-1           mol
    varsdata.decay_flux[] = pars.kappa[] * varsdata.A[]

    varsdata.A_sms[] -= varsdata.decay_flux[]

    return nothing
end


end # module