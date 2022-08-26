module Example2

import PALEOboxes as PB

"""
    ReactionExample2

Minimal example, first order decay of a variable.

Use in conjunction with a ReservoirScalar for quantity A.
"""
Base.@kwdef mutable struct ReactionExample2{P} <: PB.AbstractReaction
    base::PB.ReactionBase

    pars::P = PB.ParametersTuple(
        PB.ParDouble("kappa",   1.0, units="yr-1", description="first order decay constant"),
    )

end

function PB.register_methods!(rj::ReactionExample2)
    vars = [
        PB.VarDepScalar("A",            "mol",      "reservoir for species A"),
        PB.VarContribScalar("A_sms",    "mol yr-1", "reservoir A source - sink"),
        PB.VarPropScalar("decay_flux",  "mol yr-1", "decay flux from reservoir A"),
    ]

    PB.add_method_do!(rj, do_example2,  (PB.VarList_namedtuple(vars), ) )

    return nothing
end

# do method, called each main loop timestep
function do_example2(m::PB.ReactionMethod, pars, (varsdata, ), cellrange::PB.AbstractCellRange, deltat)
    rj = m.reaction

    # mol yr-1                   yr-1           mol
    varsdata.decay_flux[] = pars.kappa[] * varsdata.A[]

    varsdata.A_sms[] -= varsdata.decay_flux[]

    return nothing
end

end # module