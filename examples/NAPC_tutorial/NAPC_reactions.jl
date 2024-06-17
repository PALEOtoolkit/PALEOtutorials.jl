"""
    Food web biology in 1D shelf setting
"""
module ModelShelf

import PALEOboxes as PB
import Infiltrator # Julia debugger

"""
    ReactionPhytoplankton

Phytoplankton growth from Armstrong 1994

Photosynthesis reaction: 6 CO2 + 6 H2O -> C6H12O6 + 6 O2
Stoichiometry photosynthesis O:Corg:N:P 106:106:16:1 
For each unit P require 106 units Corg and for each unit Corg require 1 units O2
"""
Base.@kwdef mutable struct ReactionPhytoplankton{P} <: PB.AbstractReaction
    base::PB.ReactionBase

    pars::P = PB.ParametersTuple(
        # Constants for the NPZ model (Armstrong 1994)
        PB.ParDouble("mumax", 1.4, units="d-1",
            description="max growth rate"),
        PB.ParDouble("Ks", 1e-3, units="mol m-3",
            description="nutrient limitation factor"),
        PB.ParDouble("insol_scale", 0.005, units="",
            description="insolation scale factor"),
        PB.ParDouble("O2_thresh", 1e-6, units="mol m-3",
            description="oxygen threshold constant"),
        PB.ParDouble("stoich_PtoO2", -106.0, units="",
            description="stoichiometry, negative by convention"),
    )

end

function PB.register_methods!(rj::ReactionPhytoplankton)
 
    # Variables: 
    # 'Dep' - an external dependency (forcing, reservoir, ...)
    # 'Prop' - something we calculate
    # 'Contrib' - a flux we calculate to add to an external Target (eg a reservoir source - sink)
    vars = [
        PB.VarDep("insol",          "W m-2",        "insolation"),
        PB.VarDep("O2_conc",             "mol m-3",          "oxygen conc"),
        PB.VarContrib("O2_sms",          "mol m-3 yr-1",  "Oxygen source-sink"),
        PB.VarDep("P_conc",             "mol m-3",          "Nutrient conc"),
        PB.VarContrib("P_sms",          "mol m-3 yr-1",     "Nutrient source-sink"),
        PB.VarProp("PX_growth_rate",  "yr-1",             "phytoplankton growth rate"),
        PB.VarDep("PX_conc",          "mol m-3",          "phytoplankton concentration"),
        PB.VarContrib("PX_sms",       "mol m-3 yr-1",     "phytoplankton source-sink"),
    ]
    PB.add_method_do!(rj, grow_phyto, (PB.VarList_namedtuple(vars),))

    return nothing
end

function grow_phyto(m::PB.ReactionMethod, (vars, ), cellrange::PB.AbstractCellRange, deltat)
    rj = m.reaction
    
    mumax_yr = rj.pars.mumax.v * PB.Constants.k_daypyr # convert d-1 to yr-1
    @inbounds for i in cellrange.indices
        # NB: for numerical stability, defend against -ve values by setting rate to 0
        # yr-1

        vars.PX_growth_rate[i] = rj.pars.insol_scale.v*vars.insol[i]*mumax_yr*max(vars.P_conc[i], 0.0)/(max(vars.P_conc[i], 0.0) + rj.pars.Ks.v)

        nutrient_rate = max(vars.PX_conc[i], 0.0)*vars.PX_growth_rate[i]
        
        vars.PX_sms[i] += nutrient_rate
        vars.P_sms[i] -= nutrient_rate
        vars.O2_sms[i] -= rj.pars.stoich_PtoO2.v*nutrient_rate
       
    end

    return nothing
end

end #end module