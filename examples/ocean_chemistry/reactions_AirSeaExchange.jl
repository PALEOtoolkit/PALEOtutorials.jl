module Min_AirSeaExchange

import PALEOboxes as PB

"""
    Min_AirSeaExchange

Minimal example, just make a easy way to illustrate Air-Sea exchange.

Current this file only consider CO2 exchange between Air and Sea.

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

        PB.VarDep(             "CO2_aq_conc",               "mol m-3",              "CO2_aq concentration per cell"),
        PB.VarDepScalar(       "pCO2atm",                   "atm",                  "atmospheric pCO2, unit is atm"),
        # PB.VarDepScalar(       "pCO2PAL",                   "",                     "atmospheric pCO2 normalized to present day"),
        PB.VarContrib(         "CO2_airsea_exchange",       "mol yr-1",             "it is the calcalation for CO2_airsea_exchange"),
        PB.VarDep(             "area",                      "m2",                   "surface area"),

    ]

    PB.add_method_do!(rj, do_Min_AirSeaExchange,  (PB.VarList_namedtuple(vars), ) )

    return nothing
end

# do method, called each main loop timestep
function do_Min_AirSeaExchange(m::PB.ReactionMethod, pars, (varsdata, ), cellrange::PB.AbstractCellRange, deltat)

    rj = m.reaction

    #       mol m-3     mol m-3 atm-1                  atm     
    CO2_aq_conc_eqb  =     pars.K_0[] * varsdata.pCO2atm[]   

    for i in cellrange.indices
        
          #   mol m-3                mol m-3                                    
          CO2_aq_conc = varsdata.CO2_aq_conc[i]                 

          #                   mol yr-1            mol m-3          mol m-3          m yr-1                m2
          varsdata.CO2_airsea_exchange[i] -= (CO2_aq_conc - CO2_aq_conc_eqb) * pars.vpiston[] * varsdata.area[i]

    end    

    return nothing

end

end # module