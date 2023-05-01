module Example5

import PALEOboxes as PB

"""
    ReactionExample5

Minimal example, first order decay of a variable and transfer of decay flux with isotope fractionation

Use config file `variable_links:` to rename `input_particle*` and `output_flux`.
"""
Base.@kwdef mutable struct ReactionExample5{P} <: PB.AbstractReaction
    base::PB.ReactionBase

    pars::P = PB.ParametersTuple(
        PB.ParDouble("kappa",   1.0, units="yr-1", 
            description="first order decay constant"),
        PB.ParType(PB.AbstractData, "field_data", PB.ScalarData,
            allowed_values=PB.IsotopeTypes,
            description="disable / enable isotopes and specify isotope type"),
        PB.ParDouble("Delta",   -10.0, units="per mil", 
            description="isotope fractionation: delta(output_flux) = delta(input_particle) + Delta"),
    )

end

function PB.register_methods!(rj::ReactionExample5)
    IsotopeType = rj.pars.field_data[]
    vars = [
        PB.VarDepScalar("input_particle",           "mol",      "reservoir for input",
            attributes=(:field_data=>IsotopeType,)),
        PB.VarContribScalar("input_particle_sms",   "mol yr-1", "reservoir input source - sink",
            attributes=(:field_data=>IsotopeType,)),
        PB.VarDepScalar("input_particle_delta",     "per mil",  "reservoir for input isotope delta"),
        PB.VarPropScalar("decay_flux",              "mol yr-1", "decay flux",
            attributes=(:field_data=>IsotopeType,)),
        PB.VarContribScalar("output_flux",          "mol yr-1", "output flux",
            attributes=(:field_data=>IsotopeType,)),
    ]

    PB.add_method_do!(rj, do_example5,  (PB.VarList_namedtuple(vars), ), p=(IsotopeType, ) )

    return nothing
end

# do method, called each main loop timestep
function do_example5(m::PB.ReactionMethod, pars, (varsdata, ), cellrange::PB.AbstractCellRange, deltat)

    (IsotopeType, ) = m.p

    # mol yr-1                   yr-1           mol
    varsdata.decay_flux[] = pars.kappa[] * @PB.isotope_totaldelta(IsotopeType, 
                                                PB.get_total(varsdata.input_particle[]), # total
                                                varsdata.input_particle_delta[] + pars.Delta[]) # delta

    varsdata.input_particle_sms[] -= varsdata.decay_flux[]

    varsdata.output_flux[] += varsdata.decay_flux[]

    return nothing
end


end # module