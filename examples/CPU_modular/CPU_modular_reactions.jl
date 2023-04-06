module CPU_modular

import PALEOboxes as PB

import Infiltrator # Julia debugger

"""
    ReactionLandCPU

Land components of minimal Carbon, Phosphorus, Uranium single-box model from [Clarkson2018](@cite), and [Zhang2020](@cite)
"""
Base.@kwdef mutable struct ReactionLandCPU{P} <: PB.AbstractReaction
    base::PB.ReactionBase

    pars::P = PB.ParametersTuple(
        # Constants for the C, P, U model (Zhang etal 2020, Table 2)

        # Temperature parameters see ReactionGlobalTemperatureBerner

        # Carbon  cycle
        # A0 see ReactionReservoirScalar A 
        PB.ParDouble("k_d",         8.0e12, units="mol C/yr",   description="degassing"),
        PB.ParDouble("k_w",         8.0e12, units="mol C/yr",   description="silicate weathering"),
        PB.ParDouble("k_ox",        9.0e12, units="mol C/yr",   description="oxidative weathering"),
        PB.ParDouble("k_carb",      16e12,  units="mol C/yr",   description="carbonate weathering/burial"),
        PB.ParDouble("k_torg",      4.5e12, units="mol C/yr",   description="terrestrial organic C burial"),

        # Carbon isotopes
        # delta_LIP see ReactionFluxInterp LIP forcing
        PB.ParDouble("delta_in",    -5.0,   units="per mil",    description="composition of other inputs"),
        PB.ParDouble("Delta",       25.0-9.0,   units="per mil",    description="organic fractionation factor relative to atmosphere CO2"),

        # Phosphorus cycle
        # P0 see ReactionReservoirScalar P
        PB.ParDouble("k_Pw",        72e9,   units="mol P/yr",   description="phosphorus weathering"),

        # Uranium isotopes
        # U0 see ReactionReservoirScalar U
        PB.ParDouble("k_riv",        40e6,  units="mol U/yr",   description="river input"),
        PB.ParDouble("delta_riv",   -0.26,  units="per mil",    description="Composition of river input"),
      
        # isotope configuration
        # 'external=true' so can be set by global Parameters that apply to the whole model
        PB.ParType(PB.AbstractData, "CIsotope", PB.ScalarData,
            external=true,
            allowed_values=PB.IsotopeTypes,
            description="disable / enable carbon isotopes and specify isotope type"),
        PB.ParType(PB.AbstractData, "UIsotope", PB.ScalarData,
            external=true,
            allowed_values=PB.IsotopeTypes,
            description="disable / enable uranium isotopes and specify isotope type"),
    )

end


function PB.register_methods!(rj::ReactionLandCPU)
 
    CIsotopeType = rj.pars.CIsotope[]
    UIsotopeType = rj.pars.UIsotope[]

    # Variables: 
    # 'Dep' - an external dependency (forcing, reservoir, ...)
    # 'Prop' - something we calculate
    # 'Contrib' - a flux we calculate to add to an external Target (eg a reservoir source - sink)
    vars = [
        # Forcings
        PB.VarDepScalar("global.tforce",   "yr",           "forcing (model) time"),
        PB.VarDepScalar("global.E",        "",             "normalized E forcing"),
        PB.VarDepScalar("global.W",        "",             "normalized W forcing"),
        PB.VarDepScalar("global.V",        "",             "normalized V forcing"),
        PB.VarDepScalar("global.D",        "",             "normalized D forcing"),     
        PB.VarDepScalar("atm.pO2PAL","PAL",             "atmospheric oxygen"),

        # additional quantities derived from state variables
        PB.VarDepScalar("atm.CO2_delta",  "per mil",      "atmosphere CO2 carbon fractionation"),
        PB.VarDepScalar("atm.pCO2PAL",  "",             "atmospheric pCO2 normalized to present day"),
        PB.VarDepScalar("global.TEMP",     "K",            "global temperature"),

        # key variables that we calculate
        PB.VarPropScalar("DeltaT",  "K",            "global temperature relative to 15degC"),
        PB.VarPropScalar("f_CO2",   "",             "plant CO2 response"),
        PB.VarPropScalar("f_T",     "",             "weathering kinetics"),
       
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

        # Phosphorus fluxes
        PB.VarPropScalar("F_Pw",    "mol P yr-1",   "P weathering"),

        # Uranium fluxes
        PB.VarPropScalar("F_riv",   "mol U yr-1",   "U weathering",
            attributes=(:field_data=>UIsotopeType,)),
    ]

    # Add flux couplers
    fluxAtoLand = PB.Fluxes.FluxContribScalar(
        "fluxAtoLand.flux_", ["CO2::$CIsotopeType"],
        isotope_data=Dict())

    fluxRtoOcean = PB.Fluxes.FluxContribScalar(
        "fluxRtoOcean.flux_", ["DIC::$CIsotopeType", "TAlk", "P", "U::$UIsotopeType"],
        isotope_data=Dict())

    PB.add_method_do!(
        rj,
        do_CPU_land,  
        (
            PB.VarList_namedtuple_fields(fluxAtoLand),
            PB.VarList_namedtuple_fields(fluxRtoOcean),
            PB.VarList_namedtuple(vars),
        ),
        p = (CIsotopeType, UIsotopeType), # provide isotope types here so Julia will generate specialized (fast) code
    )

    return nothing
end


function do_CPU_land(m::PB.ReactionMethod, pars, (fluxAtoLand, fluxRtoOcean, vars), cellrange::PB.AbstractCellRange, deltat)
    CIsotopeType, UIsotopeType = m.p # This is (much) faster than rereading Parameters, as Julia generates specialized (fast) code based on the type(s) of p

    # Key variables
    vars.DeltaT[] = vars.TEMP[] - (15 + PB.Constants.k_CtoK)
    vars.f_CO2[] = 2*vars.pCO2PAL[]/(1.0 + vars.pCO2PAL[])
    vars.f_T[] = exp(0.09*vars.DeltaT[])

    # Carbon fluxes
    vars.F_w_norm[] = vars.E[]*vars.W[]*vars.V[]*vars.f_CO2[]*vars.f_T[]
    vars.F_w[] = pars.k_w[]*vars.F_w_norm[]
    vars.F_d[] = @PB.isotope_totaldelta(CIsotopeType,
        pars.k_d[]*vars.D[], # total
        pars.delta_in[]) # delta
    vars.F_ox[] = @PB.isotope_totaldelta(CIsotopeType, 
        pars.k_ox[], # total
        pars.delta_in[]) # delta
    vars.F_cw[] = @PB.isotope_totaldelta(CIsotopeType,
        pars.k_carb[], # total
        pars.delta_in[]) # delta
    vars.F_in[] = vars.F_d[] + vars.F_ox[] + vars.F_cw[]

    vars.F_torg[] = @PB.isotope_totaldelta(CIsotopeType,
        pars.k_torg[]*vars.V[]*vars.f_CO2[], # total
        vars.CO2_delta[]-pars.Delta[]) # delta
   
    # Phosphorus fluxes
    vars.F_Pw[] = pars.k_Pw[]*vars.F_w_norm[]
   
    # Uranium fluxes
    vars.F_riv[] = @PB.isotope_totaldelta(UIsotopeType, 
        pars.k_riv[]*vars.F_w_norm[],  # total
        pars.delta_riv[])              # delta

    # Fluxes
    # NB: we don't count C flux from silicate weathering (atm CO2 -> riverine DIC)
    # as that is just moving carbon from atm to ocean

    # Atmospheric fluxes 
    fluxAtoLand.CO2[]   += -vars.F_d[] - vars.F_ox[] + vars.F_torg[]

    # Riverine fluxes
    fluxRtoOcean.DIC[]  += vars.F_cw[] 
    fluxRtoOcean.TAlk[] += 2*PB.get_total(vars.F_w[]) + 2*PB.get_total(vars.F_cw[])
    fluxRtoOcean.P[]    += vars.F_Pw[]     
    fluxRtoOcean.U[]  += vars.F_riv[]

    return nothing
end

"""
    ReactionOceanCPU

Ocean component of minimal Carbon, Phosphorus, Uranium single-box model from [Clarkson2018](@cite), and [Zhang2020](@cite)
"""
Base.@kwdef mutable struct ReactionOceanCPU{P} <: PB.AbstractReaction
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
        PB.ParDouble("k_morg",      4.5e12, units="mol C/yr",   description="marine organic C burial"),

        # Carbon isotopes
        # delta_LIP see ReactionFluxInterp LIP forcing
        PB.ParDouble("Delta",       25.0,   units="per mil",    description="organic fractionation factor relative to DIC"),

        # Phosphorus cycle
        # P0 see ReactionReservoirScalar P
        PB.ParDouble("k_OrgP",      18e9,   units="mol P/yr",   description="organic P burial"),
        PB.ParDouble("k_FeP",       18e9,   units="mol P/yr",   description="Iron-sorbed P burial"),
        PB.ParDouble("k_CaP",       36e9,   units="mol P/yr",   description="Ca-bound P burial"),
        PB.ParDouble("CPoxic",      250.0,  units="mol/mol",    description="oxic (C/Porg) burial ratio"),
        PB.ParDouble("CPanoxic",    1000.0, units="mol/mol",    description="anoxic (C/Porg) burial ratio"),

        # Uranium isotopes
        # U0 see ReactionReservoirScalar U
        PB.ParDouble("k_anoxic",     6e6,   units="mol U/yr",   description="anoxic sink"),
        PB.ParDouble("k_other",      34e6,  units="mol U/yr",   description="other sinks combined"),
        PB.ParDouble("Delta_anoxic", 0.6,   units="per mil",    description="Anoxic sink fractionation"),
        PB.ParDouble("Delta_other",  0.005, units="per mil",    description="Other sinks fractionation"),

        # isotope configuration
        # 'external=true' so can be set by global Parameters that apply to the whole model
        PB.ParType(PB.AbstractData, "CIsotope", PB.ScalarData,
            external=true,
            allowed_values=PB.IsotopeTypes,
            description="disable / enable carbon isotopes and specify isotope type"),
        PB.ParType(PB.AbstractData, "UIsotope", PB.ScalarData,
            external=true,
            allowed_values=PB.IsotopeTypes,
            description="disable / enable uranium isotopes and specify isotope type"),
    )

end


function PB.register_methods!(rj::ReactionOceanCPU)
 
    CIsotopeType = rj.pars.CIsotope[]
    UIsotopeType = rj.pars.UIsotope[]

    # Variables: 
    # 'Dep' - an external dependency (forcing, reservoir, ...)
    # 'Prop' - something we calculate
    # 'Contrib' - a flux we calculate to add to an external Target (eg a reservoir source - sink)
    vars = [
        # Forcings    
        PB.VarDepScalar("atm.pO2PAL","PAL",             "atmospheric oxygen"),

        # Special-case a dependency on (riverine) alk flux for carbonate burial
        PB.VarDepScalar("flux_TAlk"=>"fluxRtoOcean.flux_TAlk",  "mol yr-1"   , "riverine alkalinity flux"),

        # State variables
        PB.VarDepScalar("P",        "mol P",        "ocean phosphorus"),
        PB.VarContribScalar("P_sms","mol P yr-1",   "ocean phosphorus source - sink"),
        PB.VarDepScalar("U",        "mol U",        "ocean uranium",
            attributes=(:field_data=>UIsotopeType,)),
        PB.VarContribScalar("U_sms","mol U yr-1",   "ocean uranium source - sink",
            attributes=(:field_data=>UIsotopeType,)),
        PB.VarContribScalar("DIC_sms","mol C yr-1",   "ocean DIC source - sink",
            attributes=(:field_data=>CIsotopeType,)),
        # additional quantities derived from state variables
        PB.VarDepScalar("DIC_delta",  "per mil",      "ocean inorganic carbon fractionation"),
        PB.VarDepScalar("P_norm",   "",             "normalized atm-ocean phosphorus"),
        PB.VarDepScalar("U_norm",   "",             "normalized ocean uranium"),
        PB.VarDepScalar("U_delta",  "per mil",      "ocean uranium fractionation"),

        # key variables that we calculate
        PB.VarPropScalar("f_anoxic","",             "ocean anoxic fraction"),
        PB.VarPropScalar("CP",      "mol/mol",      "ocean Corg:P burial ratio"),

        # Carbon fluxes
        PB.VarPropScalar("F_morg",  "mol C yr-1",   "marine Corg burial",
            attributes=(:field_data=>CIsotopeType,)),
        PB.VarPropScalar("F_carb",  "mol C yr-1",   "total Ccarb burial",
            attributes=(:field_data=>CIsotopeType,)),

        # Phosphorus fluxes
        PB.VarPropScalar("F_OrgP",  "mol P yr-1",   "organic P burial"),
        PB.VarPropScalar("F_FeP",   "mol P yr-1",   "Fe-sorbed P burial"),
        PB.VarPropScalar("F_CaP",   "mol P yr-1",   "Ca-bound P burial"),

        # Uranium fluxes
        PB.VarPropScalar("F_anoxic","mol U yr-1",   "Anoxic U sink",
            attributes=(:field_data=>UIsotopeType,)),
        PB.VarPropScalar("F_other", "mol U yr-1",   "Other U sinks",
            attributes=(:field_data=>UIsotopeType,)),
    ]

    PB.add_method_do!(
        rj,
        do_CPU_ocean,  
        (
            PB.VarList_namedtuple(vars),
        ),
        p = (CIsotopeType, UIsotopeType), # provide isotope types here so Julia will generate specialized (fast) code
    )

    return nothing
end


function do_CPU_ocean(m::PB.ReactionMethod, pars, (vars, ), cellrange::PB.AbstractCellRange, deltat)
    CIsotopeType, UIsotopeType = m.p # This is (much) faster than rereading Parameters, as Julia generates specialized (fast) code based on the type(s) of p

    # Key variables
    vars.f_anoxic[] = 1.0/(1.0 + exp(-pars.k_anox[]*(pars.k_u[]*vars.P_norm[]-vars.pO2PAL[])))    

    # Carbon fluxes
    vars.F_morg[] = @PB.isotope_totaldelta(CIsotopeType,
        pars.k_morg[]*vars.P_norm[], # total
        vars.DIC_delta[]-pars.Delta[]) # delta
   
    vars.F_carb[] = @PB.isotope_totaldelta(CIsotopeType,
        0.5*vars.flux_TAlk[], # total from instantaneous alkalinity balance
        vars.DIC_delta[]) # delta assume no fractionation of carbonate burial relative to DIC
    
    # Phosphorus fluxes
    vars.CP[] = vars.f_anoxic[]/pars.CPanoxic[] + (1-vars.f_anoxic[])/pars.CPoxic[]
    vars.F_OrgP[] = PB.get_total(vars.F_morg[])*vars.CP[]
    vars.F_FeP[] = pars.k_FeP[]*(1-vars.f_anoxic[])
    vars.F_CaP[] = pars.k_CaP[]*vars.P_norm[]

    # Uranium fluxes
    vars.F_anoxic[] = @PB.isotope_totaldelta(UIsotopeType, 
        pars.k_anoxic[]*vars.U_norm[]*vars.f_anoxic[]/pars.f_anoxic0[], # total
        vars.U_delta[] + pars.Delta_anoxic[]) # delta
    vars.F_other[] = @PB.isotope_totaldelta(UIsotopeType,
        pars.k_other[]*vars.U_norm[]*(1-vars.f_anoxic[])/(1-pars.f_anoxic0[]), # total
        vars.U_delta[] + pars.Delta_other[]) # delta


    # Reservoir source-sink
    vars.DIC_sms[] -= vars.F_morg[] + vars.F_carb[]
    vars.P_sms[] -=  vars.F_OrgP[] + vars.F_FeP[] + vars.F_CaP[]
    vars.U_sms[] -= vars.F_anoxic[] + vars.F_other[]

    return nothing
end

end # module
