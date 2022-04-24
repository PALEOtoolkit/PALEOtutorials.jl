module ModelCPU

import PALEOboxes as PB

import Infiltrator # Julia debugger

"""
    ReactionModelCPU

Minimal Carbon, Phosphorus, Uranium single-box model from [Clarkson2018](@cite), and [Zhang2020](@cite)
"""
Base.@kwdef mutable struct ReactionModelCPU{P} <: PB.AbstractReaction
    base::PB.ReactionBase

    pars::P = PB.ParametersTuple(
        # Constants for the C, P, U model (Zhang etal 2020, Table 2)

        # Temperature parameters see ReactionGlobalTemperatureBerner

        # Ocean anoxia
        PB.ParDouble("f_anoxic0",   0.0025, units="",           description="ocean anoxia present day anoxic fraction"),
        PB.ParDouble("k_anox",      12.0,   units="",           description="ocean anoxia sharpness of transition"),
        PB.ParDouble("k_u",         0.5,    units="",           description="ocean anoxia nutrient utilization efficiency"),

        # Carbon  cycle
        # A0 see ReactionReservoirScalar A 
        PB.ParDouble("k_d",         8.0e12, units="mol C/yr",   description="degassing"),
        PB.ParDouble("k_w",         8.0e12, units="mol C/yr",   description="silicate weathering"),
        PB.ParDouble("k_ox",        9.0e12, units="mol C/yr",   description="oxidative weathering"),
        PB.ParDouble("k_carb",      16e12,  units="mol C/yr",   description="carbonate weathering/burial"),
        PB.ParDouble("k_morg",      4.5e12, units="mol C/yr",   description="marine organic C burial"),
        PB.ParDouble("k_torg",      4.5e12, units="mol C/yr",   description="terrestrial organic C burial"),

        # Carbon isotopes
        # delta_LIP see ReactionFluxInterp LIP forcing
        PB.ParDouble("delta_in",    -5.0,   units="per mil",    description="composition of other inputs"),
        PB.ParDouble("Delta",       25.0,   units="per mil",    description="organic fractionation factor"),

        # Phosphorus cycle
        # P0 see ReactionReservoirScalar P
        PB.ParDouble("k_Pw",        72e9,   units="mol P/yr",   description="phosphorus weathering"),
        PB.ParDouble("k_OrgP",      18e9,   units="mol P/yr",   description="organic P burial"),
        PB.ParDouble("k_FeP",       18e9,   units="mol P/yr",   description="Iron-sorbed P burial"),
        PB.ParDouble("k_CaP",       36e9,   units="mol P/yr",   description="Ca-bound P burial"),
        PB.ParDouble("CPoxic",      250.0,  units="mol/mol",    description="oxic (C/Porg) burial ratio"),
        PB.ParDouble("CPanoxic",    1000.0, units="mol/mol",    description="anoxic (C/Porg) burial ratio"),

        # Uranium isotopes
        # U0 see ReactionReservoirScalar U
        PB.ParDouble("k_riv",        40e6,  units="mol U/yr",   description="river input"),
        PB.ParDouble("k_anoxic",     6e6,   units="mol U/yr",   description="anoxic sink"),
        PB.ParDouble("k_other",      34e6,  units="mol U/yr",   description="other sinks combined"),
        PB.ParDouble("delta_riv",   -0.26,  units="per mil",    description="Composition of river input"),
        PB.ParDouble("Delta_anoxic", 0.6,   units="per mil",    description="Anoxic sink fractionation"),
        PB.ParDouble("Delta_other",  0.005, units="per mil",    description="Other sinks fractionation"),       
    )

end


function PB.register_methods!(rj::ReactionModelCPU)
 
    _, CIsotopeType = PB.split_nameisotope("::CIsotope", rj.external_parameters)
    _, UIsotopeType = PB.split_nameisotope("::UIsotope", rj.external_parameters)

    # Variables: 
    # 'Dep' - an external dependency (forcing, reservoir, ...)
    # 'Prop' - something we calculate
    # 'Contrib' - a flux we calculate to add to an external Target (eg a reservoir source - sink)
    vars = [
        # Forcings
        PB.VarDepScalar("tforce",   "yr",           "forcing (model) time"),
        PB.VarDepScalar("E",        "",             "normalized E forcing"),
        PB.VarDepScalar("W",        "",             "normalized W forcing"),
        PB.VarDepScalar("V",        "",             "normalized V forcing"),
        PB.VarDepScalar("D",        "",             "normalized D forcing"),     
        PB.VarDepScalar("pO2PAL","PAL",             "atmospheric oxygen"),

        # State variables
        PB.VarDepScalar("A",        "mol C",        "atm-ocean inorganic carbon",
            attributes=(:field_data=>CIsotopeType,)),
        PB.VarContribScalar("A_sms","mol C yr-1",   "atm-ocean inorganic carbon source - sink",
            attributes=(:field_data=>CIsotopeType,)),
        PB.VarDepScalar("P",        "mol P",        "ocean phosphorus"),
        PB.VarContribScalar("P_sms","mol P yr-1",   "ocean phosphorus source - sink"),
        PB.VarDepScalar("U",        "mol U",        "ocean uranium",
            attributes=(:field_data=>UIsotopeType,)),
        PB.VarContribScalar("U_sms","mol U yr-1",   "ocean uranium source - sink",
            attributes=(:field_data=>UIsotopeType,)),
        # additional quantities derived from state variables
        PB.VarDepScalar("A_norm",   "",             "normalized atm-ocean inorganic carbon"),
        PB.VarDepScalar("A_delta",  "per mil",      "atmosphere-ocean inorganic carbon fractionation"),
        PB.VarDepScalar("pCO2PAL",  "",             "atmospheric pCO2 normalized to present day"),
        PB.VarDepScalar("P_norm",   "",             "normalized atm-ocean phosphorus"),
        PB.VarDepScalar("U_norm",   "",             "normalized ocean uranium"),
        PB.VarDepScalar("U_delta",  "per mil",      "ocean uranium fractionation"),
        PB.VarDepScalar("TEMP",     "K",            "global temperature"),

        # key variables that we calculate
        PB.VarPropScalar("DeltaT",  "K",            "global temperature relative to 15degC"),
        PB.VarPropScalar("f_CO2",   "",             "plant CO2 response"),
        PB.VarPropScalar("f_T",     "",             "weathering kinetics"),
        PB.VarPropScalar("f_anoxic","",             "ocean anoxic fraction"),
        PB.VarPropScalar("CP",      "mol/mol",      "ocean Corg:P burial ratio"),

        # Carbon fluxes
        PB.VarPropScalar("F_w_norm", "",            "relative silicate weathering"),
        PB.VarPropScalar("F_w",     "mol C yr-1",   "silicate weathering"),
        PB.VarPropScalar("F_d",     "mol C yr-1",   "carbonate degassing",
            attributes=(:field_data=>CIsotopeType,)),
        PB.VarPropScalar("F_ox",    "mol C yr-1",   "plant CO2 response",
            attributes=(:field_data=>CIsotopeType,)),
        PB.VarPropScalar("F_cw",    "mol C yr-1",   "carbonate weathering",
            attributes=(:field_data=>CIsotopeType,)),
        PB.VarPropScalar("F_in",    "mol C yr-1",   "aggregate C input",
            attributes=(:field_data=>CIsotopeType,)),
        PB.VarPropScalar("F_torg",  "mol C yr-1",   "terrestrial Corg burial",
            attributes=(:field_data=>CIsotopeType,)),
        PB.VarPropScalar("F_morg",  "mol C yr-1",   "marine Corg burial",
            attributes=(:field_data=>CIsotopeType,)),
        PB.VarPropScalar("F_org",   "mol C yr-1",   "total Corg burial",
            attributes=(:field_data=>CIsotopeType,)),
        PB.VarPropScalar("F_carb",  "mol C yr-1",   "total Ccarb burial",
            attributes=(:field_data=>CIsotopeType,)),

        # Phosphorus fluxes
        PB.VarPropScalar("F_Pw",    "mol P yr-1",   "P weathering"),
        PB.VarPropScalar("F_OrgP",  "mol P yr-1",   "organic P burial"),
        PB.VarPropScalar("F_FeP",   "mol P yr-1",   "Fe-sorbed P burial"),
        PB.VarPropScalar("F_CaP",   "mol P yr-1",   "Ca-bound P burial"),

        # Uranium fluxes
        PB.VarPropScalar("F_riv",   "mol U yr-1",   "U weathering",
            attributes=(:field_data=>UIsotopeType,)),
        PB.VarPropScalar("F_anoxic","mol U yr-1",   "Anoxic U sink",
            attributes=(:field_data=>UIsotopeType,)),
        PB.VarPropScalar("F_other", "mol U yr-1",   "Other U sinks",
            attributes=(:field_data=>UIsotopeType,)),
    ]

    p = (CIsotopeType, UIsotopeType)
    PB.add_method_do!(
        rj,
        do_CPU,  
        (
            PB.VarList_namedtuple(vars),
        ),
        p = p,
    )

    return nothing
end


function do_CPU(m::PB.ReactionMethod, (vars, ), cellrange::PB.AbstractCellRange, deltat)
    CIsotopeType, UIsotopeType = m.p
    pars = m.reaction.pars

    # Key variables
    vars.DeltaT[] = vars.TEMP[] - (15 + PB.Constants.k_CtoK)
    vars.f_CO2[] = 2*vars.pCO2PAL[]/(1.0 + vars.pCO2PAL[])
    vars.f_T[] = exp(0.09*vars.DeltaT[])
    vars.f_anoxic[] = 1.0/(1.0 + exp(-pars.k_anox.v*(pars.k_u.v*vars.P_norm[]-vars.pO2PAL[])))    

    # Carbon fluxes
    vars.F_w_norm[] = vars.E[]*vars.W[]*vars.V[]*vars.f_CO2[]*vars.f_T[]
    vars.F_w[] = pars.k_w.v*vars.F_w_norm[]
    vars.F_d[] = @PB.isotope_totaldelta(CIsotopeType,
        pars.k_d.v*vars.D[], # total
        pars.delta_in.v) # delta
    vars.F_ox[] = @PB.isotope_totaldelta(CIsotopeType, 
        pars.k_ox.v, # total
        pars.delta_in.v) # delta
    vars.F_cw[] = @PB.isotope_totaldelta(CIsotopeType,
        pars.k_carb.v, # total
        pars.delta_in.v) # delta
    vars.F_in[] = vars.F_d[] + vars.F_ox[] + vars.F_cw[]

    vars.F_torg[] = @PB.isotope_totaldelta(CIsotopeType,
        pars.k_torg.v*vars.V[]*vars.f_CO2[], # total
        vars.A_delta[]-pars.Delta.v) # delta
    vars.F_morg[] = @PB.isotope_totaldelta(CIsotopeType,
        pars.k_morg.v*vars.P_norm[], # total
        vars.A_delta[]-pars.Delta.v) # delta
    vars.F_org[] = vars.F_morg[] + vars.F_torg[]
   
    vars.F_carb[] = @PB.isotope_totaldelta(CIsotopeType,
        vars.F_w[] + PB.get_total(vars.F_cw[]), # total from instantaneous alkalinity balance
        vars.A_delta[]) # delta assume no fractionation of carbonate burial relative to A
    
    # Phosphorus fluxes
    vars.F_Pw[] = pars.k_Pw.v*vars.F_w_norm[]
    vars.CP[] = vars.f_anoxic[]/pars.CPanoxic.v + (1-vars.f_anoxic[])/pars.CPoxic.v
    vars.F_OrgP[] = PB.get_total(vars.F_morg[])*vars.CP[]
    vars.F_FeP[] = pars.k_FeP.v*(1-vars.f_anoxic[])
    vars.F_CaP[] = pars.k_CaP.v*vars.P_norm[]

    # Uranium fluxes
    vars.F_riv[] = @PB.isotope_totaldelta(UIsotopeType, 
        pars.k_riv.v*vars.F_w_norm[],  # total
        pars.delta_riv.v)              # delta
    vars.F_anoxic[] = @PB.isotope_totaldelta(UIsotopeType, 
        pars.k_anoxic.v*vars.U_norm[]*vars.f_anoxic[]/pars.f_anoxic0.v, # total
        vars.U_delta[] + pars.Delta_anoxic.v) # delta
    vars.F_other[] = @PB.isotope_totaldelta(UIsotopeType,
        pars.k_other.v*vars.U_norm[]*(1-vars.f_anoxic[])/(1-pars.f_anoxic0.v), # total
        vars.U_delta[] + pars.Delta_other.v) # delta


    # Reservoir source-sink
    vars.A_sms[] += vars.F_in[] - vars.F_org[] - vars.F_carb[]  # F_LIP is applied directly
    vars.P_sms[] += vars.F_Pw[] - vars.F_OrgP[] - vars.F_FeP[] - vars.F_CaP[]
    vars.U_sms[] += vars.F_riv[] - vars.F_anoxic[] - vars.F_other[]

    return nothing
end

# Install create_reactionXXX factories when module imported
function __init__()
    PB.add_reaction_factory(ReactionModelCPU)
    return nothing
end


end # module
