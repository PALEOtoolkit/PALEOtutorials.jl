module Min_AirSeaExchange

import PALEOboxes as PB
using PALEOboxes.DocStrings # for $(PARS) and $(METHODS_DO)

"""
    Reaction_Min_AirSeaExchange

Minimal example, just make a easy way to illustrate Air-Sea exchange.

This implements exchange between Air and Sea for a generic gas `X` with fixed Henry law coefficient `K_0`
and piston velocity `vpiston`.

The Reaction-local Variables `X_aq_conc`, `pXatm`, `X_airsea_exchange` should be linked to the appropriate variables using the
`variable_links:` section in the .yaml file.

# Parameters
$(PARS)

# Methods and Variables
$(METHODS_DO)
"""
Base.@kwdef mutable struct Reaction_Min_AirSeaExchange{P} <: PB.AbstractReaction

    base::PB.ReactionBase

    pars::P = PB.ParametersTuple(
        
        PB.ParDouble("K_0",              3.4e-2*1e3, units="mol m-3 atm-1",      description="Henry Law coefficient"),
        PB.ParDouble("vpiston",          1138.8,     units="m yr-1",             description="piston value for a whole year, 365 days"),

    )

end

function PB.register_methods!(rj::Reaction_Min_AirSeaExchange)

    vars = [

        PB.VarDep(             "X_aq_conc",               "mol m-3",              "ocean concentration per cell"),
        PB.VarDepScalar(       "pXatm",                   "atm",                  "atmospheric partial pressure, unit is atm"),
        PB.VarContrib(         "X_airsea_exchange",       "mol yr-1",             "calculated airsea exchange flux for gas X"),
        PB.VarDep(             "area",                    "m2",                   "surface area"),

    ]

    PB.add_method_do!(rj, do_Min_AirSeaExchange,  (PB.VarList_namedtuple(vars), ) )

    return nothing
end

# do method, called each main loop timestep
function do_Min_AirSeaExchange(m::PB.ReactionMethod, pars, (varsdata, ), cellrange::PB.AbstractCellRange, deltat)

    #       mol m-3     mol m-3 atm-1            atm     
    X_aq_conc_eqb  =     pars.K_0[] * varsdata.pXatm[]   

    for i in cellrange.indices
        
          #   mol m-3                mol m-3                                    
          X_aq_conc = varsdata.X_aq_conc[i]                 

          #                   mol yr-1      mol m-3          mol m-3          m yr-1                m2
          varsdata.X_airsea_exchange[i] -= (X_aq_conc - X_aq_conc_eqb) * pars.vpiston[] * varsdata.area[i]

    end    

    return nothing

end

end # module