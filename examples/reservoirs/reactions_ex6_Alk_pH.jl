module Min_Alk_pH

using SimpleNonlinearSolve
using StaticArrays
using NonlinearSolve

import PALEOboxes as PB
import PALEOcopse
import PALEOmodel

"""
    Min_Alk_pH

Minimal example, TAlk_conc is first order decay of a variable.


"""
Base.@kwdef mutable struct Reaction_Alk_pH{P} <: PB.AbstractReaction
    base::PB.ReactionBase

    pars::P = PB.ParametersTuple(
        
        PB.ParDouble("kappa",            1.0,        units="yr-1",          description="first order decay constant"),
        PB.ParDouble("TAlk_conc_change",   10.0e-6,    units="mol kg-1",      description="TA concentration change every kappa"),
        PB.ParDouble("density",          1027.0,     units="kg m-3",        description="current seawater density"),
        PB.ParDouble("K_1",              1.4e-6,     units="mol kg-1",      description="equilibrium constant of CO2_aq and HCO3-"),
        PB.ParDouble("K_2",              1.2e-9,     units="mol kg-1",      description="equilibrium constant of HCO3- and CO32-"),
        PB.ParDouble("K_w",              6.0e-14,    units="mol2 kg-2",     description="equilibrium constant of water at S=35, T=25°C"),
        PB.ParDouble("K_B",              2.5e-9,     units="mol kg-1",      description="equilibrium constant of B(OH)4-"),
        PB.ParDouble("B_total",          4.2e-4,     units="mol kg-1",      description="total concentrations of B(OH)4- and B(OH)3"),
        
    )

end

function PB.register_methods!(rj::Reaction_Alk_pH)
    vars = [
        PB.VarDep("DIC",                 "mol",           "reservoir for species DIC"),
        PB.VarDep("DIC_conc",            "mol m-3",       "DIC concentration"),                  
        PB.VarContrib("DIC_sms",         "mol yr-1",      "reservoir DIC source - sink"),
        PB.VarDep("TAlk",                "mol",           "reservoir for species TA"),
        PB.VarDep("TAlk_conc",           "mol m-3",       "TA concentration"),                    
        PB.VarContrib("TAlk_sms",        "mol yr-1",      "reservoir TA source - sink"),
        PB.VarProp("TAlk_decay_flux",    "mol yr-1",      "decay flux from reservoir TA"),        
        PB.VarConstraint("TAlk_error",   "mol m-3",       "in order to solve TA, we set it"),
        PB.VarProp("HCO3_conc",          "mol m-3",       "HCO3- concentration"),                 
        PB.VarProp("CO3_conc",           "mol m-3",       "CO32- concentration"),
        PB.VarProp("CO2_aq_conc",        "mol m-3",       "CO2_aq concentration"),
        PB.VarProp("BOH4_conc",          "mol m-3",       "BOH4- concentration"),
        PB.VarProp("H_conc",             "mol m-3",       "concentration of H+"),
        PB.VarProp("OH_conc",            "mol m-3",       "concentration of OH-"),
        PB.VarState("pH",                "",              "it is the calcalation for pH"),          
        PB.VarDep("volume",              "m3",            "ocean volume"),                        
    ]

    PB.add_method_do!(rj, do_Min_Alk_pH,  (PB.VarList_namedtuple(vars), ) )

    PB.add_method_setup!(rj, setup_carbchem, (PB.VarList_namedtuple(vars), ),)

    return nothing
end

function setup_carbchem(  m::PB.ReactionMethod, pars, (vars, ), cellrange::PB.AbstractCellRange, attribute_name )
    
    attribute_name in (:initial_value, :norm_value) || return
    
    for i in cellrange.indices

       vars.pH[i] = 8.0

    end

    return nothing

end


# do method, called each main loop timestep

function do_Min_Alk_pH(m::PB.ReactionMethod, pars, (varsdata, ), cellrange::PB.AbstractCellRange, deltat)
    
    rj = m.reaction
    
    for i in cellrange.indices

        #                mol yr-1           yr-1                mol kg-1           kg m-3                   m3
        varsdata.TAlk_decay_flux[i] = pars.kappa[] * pars.TAlk_conc_change[] * pars.density[] * varsdata.volume[i]      

        #         mol yr-1                    mol yr-1            
        varsdata.TAlk_sms[i] = varsdata.TAlk_decay_flux[i] 

        #  mol kg-1                mol m-3           kg m-3
        DIC_conc_kg = varsdata.DIC_conc[i] / pars.density[] 
        

        # mol kg-1               mol m-3           kg m-3
        TAlk_conc_kg = varsdata.TAlk_conc[i] / pars.density[]

        # mol kg-1    =             mol kg-1
        H_conc_kg     = 10^( -varsdata.pH[i] )                                                                         

        #     mol kg-1      mol kg-1           mol kg-1  mol kg-1      mol kg-1   mol kg-1     mol kg-1     
        CO2_aq_conc_kg = DIC_conc_kg / ( 1 + pars.K_1[]/H_conc_kg + (pars.K_1[]*pars.K_2[])/((H_conc_kg)^2) )

        #   mol kg-1      mol kg-1            mol kg-1 mol kg-1     mol kg-1  mol kg-1    
        HCO3_conc_kg = DIC_conc_kg / ( 1 + H_conc_kg/pars.K_1[] + pars.K_2[]/H_conc_kg )

        #  mol kg-1      mol kg-1          mol kg-1   mol kg-1      mol kg-1        mol kg-1   mol kg-1
        CO3_conc_kg = DIC_conc_kg / ( 1 + H_conc_kg/pars.K_2[] + ((H_conc_kg)^2)/(pars.K_1[]*pars.K_2[]) )

        #   mol kg-1          mol kg-1          mol kg-1   mol kg-1  
        BOH4_conc_kg =  pars.B_total[] / ( 1 + H_conc_kg/pars.K_B[] )

        # mol kg-1    mol2 kg-2    mol kg-1     
        OH_conc_kg = pars.K_w[] / H_conc_kg

        #       mol kg-1       mol kg-1          mol kg-1       mol kg-1     mol kg-1     mol kg-1                                 
        TAlk_conc_kg_calcu = HCO3_conc_kg + 2 * CO3_conc_kg + BOH4_conc_kg + OH_conc_kg  - H_conc_kg  

        #          mol m-3         kg m-3      mol kg-1
        varsdata.H_conc[i] = pars.density[] * H_conc_kg

        #           mol m-3          kg m-3      mol kg-1
        varsdata.OH_conc[i] = pars.density[] * OH_conc_kg     

        #             mol m-3           kg m-3       mol kg-1
        varsdata.HCO3_conc[i] = pars.density[] * HCO3_conc_kg        

        #            mol m-3           kg m-3      mol kg-1
        varsdata.CO3_conc[i] = pars.density[] * CO3_conc_kg     

        #               mol m-3           kg m-3         mol kg-1
        varsdata.CO2_aq_conc[i] = pars.density[] * CO2_aq_conc_kg  

        #             mol m-3           kg m-3       mol kg-1
        varsdata.BOH4_conc[i] = pars.density[] * BOH4_conc_kg                                           

        #            mol m-3               mol m-3           mol kg-1          kg m-3                  
        varsdata.TAlk_error[i] = varsdata.TAlk_conc[i] - TAlk_conc_kg_calcu * pars.density[]
    
    end
    

    return nothing


end



end 

# module