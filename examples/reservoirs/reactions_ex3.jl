module Example3

import PALEOboxes as PB

"""
    ReactionExample3

Minimal example, first order decay of a variable and transfer of decay flux.

Use config file `variable_links:` to rename `input_particle*` and `output_flux`.
"""
Base.@kwdef mutable struct ReactionExample3{P} <: PB.AbstractReaction
    base::PB.ReactionBase

    pars::P = PB.ParametersTuple(
        PB.ParDouble("kappa",   1.0, units="yr-1", description="first order decay constant"),
    )

end

function PB.register_methods!(rj::ReactionExample3)
    vars = [
        PB.VarDepScalar("input_particle",           "mol",      "reservoir for input"),
        PB.VarContribScalar("input_particle_sms",   "mol yr-1", "reservoir input source - sink"),
        PB.VarPropScalar("decay_flux",              "mol yr-1", "decay flux"),
        PB.VarContribScalar("output_flux",          "mol yr-1", "output flux"),
    ]

    PB.add_method_do!(rj, do_example3,  (PB.VarList_namedtuple(vars), ) )

    return nothing
end

# do method, called each main loop timestep
function do_example3(m::PB.ReactionMethod, (varsdata, ), cellrange::PB.AbstractCellRange, deltat)
    rj = m.reaction

    # mol yr-1                   yr-1           mol
    varsdata.decay_flux[] = rj.pars.kappa.v * varsdata.input_particle[]

    varsdata.input_particle_sms[] -= varsdata.decay_flux[]

    varsdata.output_flux[] += varsdata.decay_flux[]

    return nothing
end

# Install create_reactionXXX factories when module imported
function __init__()
    PB.add_reaction_factory(ReactionExample3)
    return nothing
end


end # module