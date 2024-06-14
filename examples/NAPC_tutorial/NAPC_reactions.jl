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

        nut_rate = max(vars.PX_conc[i], 0.0)*vars.PX_growth_rate[i]
        
        vars.PX_sms[i] += nut_rate
        vars.P_sms[i] -= nut_rate
        vars.O2_sms[i] -= rj.pars.stoich_PtoO2.v*nut_rate
       
    end

    return nothing
end

"""
    ReactionZooplankton

Zooplankton growth from Armstrong 1994

Zooplankton growth stops below threshold phytoplankton concentration

Stoichiometry respiration O:Corg:N:P 106:106:16:1
"""
Base.@kwdef mutable struct ReactionZooplankton{P} <: PB.AbstractReaction
    base::PB.ReactionBase

    pars::P = PB.ParametersTuple(
        # Constants for the NPZ model (Armstrong 1994)
        PB.ParDouble("gamma", 0.4, units="",
            description="assimilation efficiency"),
        PB.ParDouble("Hmax", 1.4, units="d-1",
            description="max harvest rate"),
        PB.ParDouble("Kp", 2e-3, units="mol m-3",
            description="full-saturation constant"), 
        PB.ParDouble("phyt_thresh", 1e-6, units="mol m-3",
            description="feeding threshold constant"),
        PB.ParDouble("O2_thresh", 1e-6, units="mol m-3",
            description="oxygen threshold constant"),
        PB.ParDouble("stoich_PtoO2", -106.0, units="",
            description="stoichiometry"),
    )

end

function PB.register_methods!(rj::ReactionZooplankton)
 
    # Variables: 
    # 'Dep' - an external dependency (forcing, reservoir, ...)
    # 'Prop' - something we calculate
    # 'Contrib' - a flux we calculate to add to an external Target (eg a reservoir source - sink)
    vars = [
        PB.VarProp("ZX_growth_rate",  "yr-1",             "zooplankton growth rate"),
        PB.VarDep("PX_conc",          "mol m-3",          "phytoplankton concentration"),
        PB.VarDep("ZX_conc",          "mol m-3",          "zooplankton concentration"),
        PB.VarContrib("ZX_sms",       "mol m-3 yr-1",     "zooplankton source-sink"),
        PB.VarContrib("PX_sms",       "mol m-3 yr-1",     "phytoplankton source-sink"),
        PB.VarContrib("P_sms",          "mol m-3 yr-1",     "Nutrient source-sink"),
        PB.VarDep("O2_conc",             "mol m-3",          "oxygen conc"),
        PB.VarContrib("O2_sms",          "mol m-3 yr-1",     "oxygen source-sink"),
    ]
    PB.add_method_do!(rj, grow_zoo, (PB.VarList_namedtuple(vars),))

    return nothing
end

function grow_zoo(m::PB.ReactionMethod, (vars, ), cellrange::PB.AbstractCellRange, deltat)
    rj = m.reaction

    Hmax_yr = rj.pars.Hmax.v * PB.Constants.k_daypyr # convert d-1 to yr-1
    HoverK_yr = Hmax_yr/rj.pars.Kp.v
    @inbounds for i in cellrange.indices
        # NB: for numerical stability, defend against -ve values by setting rate to 0
        # yr-1
        if (vars.PX_conc[i] > rj.pars.phyt_thresh.v) && (vars.O2_conc[i] > rj.pars.O2_thresh.v)
            vars.ZX_growth_rate[i] = (max(vars.PX_conc[i], 0.0) - rj.pars.phyt_thresh.v)*(rj.pars.gamma.v*HoverK_yr)
        else
            vars.ZX_growth_rate[i] = 0.0         
        end
        
        phyt_rate = max(vars.ZX_conc[i], 0.0)*vars.ZX_growth_rate[i]
        vars.ZX_sms[i] += phyt_rate 
        vars.PX_sms[i] -= phyt_rate / rj.pars.gamma.v
        phyt_release = (phyt_rate / rj.pars.gamma.v) - phyt_rate
        vars.P_sms[i] += phyt_release 
        vars.O2_sms[i] += phyt_release*rj.pars.stoich_PtoO2.v
       
    end

    return nothing
end

end #end module