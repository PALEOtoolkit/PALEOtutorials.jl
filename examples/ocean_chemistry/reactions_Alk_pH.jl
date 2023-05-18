module Min_Alk_pH

import PALEOboxes as PB
using PALEOboxes.DocStrings # for $(PARS) and $(METHODS_DO)

"""
    Reaction_Alk_pH

Minimal example for aqueous carbonate system.

Solves for carbon, boron and water species given `pH`, calculates difference `TAlk_error` from
required alkalinity.

Use in conjunction with a DAE solver, where this Reaction provides an algebraic constraint `TAlk_error` on `pH`.

# Parameters
$(PARS)

# Methods and Variables
$(METHODS_DO)
"""
Base.@kwdef mutable struct Reaction_Alk_pH{P} <: PB.AbstractReaction
    base::PB.ReactionBase

    pars::P = PB.ParametersTuple(
        
        PB.ParDouble("K_1",              1.4e-6,     units="mol kg-1",      description="equilibrium constant of CO2_aq and HCO3-"),
        PB.ParDouble("K_2",              1.2e-9,     units="mol kg-1",      description="equilibrium constant of HCO3- and CO32-"),
        PB.ParDouble("K_w",              6.0e-14,    units="mol^2 kg-2",     description="equilibrium constant of water at S=35, T=25°C"),
        PB.ParDouble("K_B",              2.5e-9,     units="mol kg-1",      description="equilibrium constant of B(OH)4-"),       
    )

end

function PB.register_methods!(rj::Reaction_Alk_pH)
    vars = [
        PB.VarDep("DIC_conc",            "mol m-3",       "DIC concentration"),                  
        PB.VarDep("TAlk_conc",           "mol m-3",       "TA concentration"),
        PB.VarDep("B_conc",              "mol m-3",       "total Boron concentration"),               
        PB.VarConstraint("TAlk_error",   "mol m-3",       "in order to solve TA, we set it"),
        PB.VarProp("HCO3_conc",          "mol m-3",       "HCO3- concentration"),                 
        PB.VarProp("CO3_conc",           "mol m-3",       "CO32- concentration"),
        PB.VarProp("CO2_aq_conc",        "mol m-3",       "CO2_aq concentration"),
        PB.VarProp("BOH3_conc",          "mol m-3",       "BOH3 concentration"),
        PB.VarProp("BOH4_conc",          "mol m-3",       "BOH4- concentration"),
        PB.VarProp("H_conc",             "mol m-3",       "concentration of H+"),
        PB.VarProp("OH_conc",            "mol m-3",       "concentration of OH-"),
        PB.VarState("pH",                "",              "it is the calcalation for pH"),          
        PB.VarDep("density",             "kg m-3",        "ocean density"),                  
    ]

    PB.add_method_do!(rj, do_Min_Alk_pH,  (PB.VarList_namedtuple(vars), ) )

    PB.add_method_setup!(rj, setup_carbchem, (PB.VarList_namedtuple(vars), ),)

    return nothing
end

# called at model start
# provide an initial value for pH (exact value is not important, just needs to be in a reasonable range)
function setup_carbchem(  m::PB.ReactionMethod, pars, (vars, ), cellrange::PB.AbstractCellRange, attribute_name )
    
    attribute_name in (:initial_value, :norm_value) || return
    
    for i in cellrange.indices

       vars.pH[i] = 8.0

    end

    return nothing

end


# do method, called each main loop timestep

function do_Min_Alk_pH(m::PB.ReactionMethod, pars, (varsdata, ), cellrange::PB.AbstractCellRange, deltat)
    
    # rj = m.reaction
    
    for i in cellrange.indices
        density = varsdata.density[i]

        #  mol kg-1                mol m-3           kg m-3
        DIC_conc_kg = varsdata.DIC_conc[i] / density         
        B_total_kg = varsdata.B_conc[i] / density

        # mol kg-1    = mol L-1                / kg m-3  * L m-3
        H_conc_kg     = 10^( -varsdata.pH[i] ) / density * 1000.0

        #     mol kg-1      mol kg-1           mol kg-1  mol kg-1      mol kg-1   mol kg-1     mol kg-1     
        CO2_aq_conc_kg = DIC_conc_kg / ( 1 + pars.K_1[]/H_conc_kg + (pars.K_1[]*pars.K_2[])/((H_conc_kg)^2) )

        #   mol kg-1      mol kg-1            mol kg-1 mol kg-1     mol kg-1  mol kg-1    
        HCO3_conc_kg = DIC_conc_kg / ( 1 + H_conc_kg/pars.K_1[] + pars.K_2[]/H_conc_kg )

        #  mol kg-1      mol kg-1          mol kg-1   mol kg-1      mol kg-1        mol kg-1   mol kg-1
        CO3_conc_kg = DIC_conc_kg / ( 1 + H_conc_kg/pars.K_2[] + ((H_conc_kg)^2)/(pars.K_1[]*pars.K_2[]) )
       
        #   mol kg-1          mol kg-1          mol kg-1   mol kg-1  
        BOH4_conc_kg =  B_total_kg / ( 1 + H_conc_kg/pars.K_B[] )

        BOH3_conc_kg = B_total_kg - BOH4_conc_kg

        # mol kg-1    mol2 kg-2    mol kg-1     
        OH_conc_kg = pars.K_w[] / H_conc_kg

        #       mol kg-1       mol kg-1          mol kg-1       mol kg-1     mol kg-1     mol kg-1                                 
        TAlk_conc_kg_calcu = HCO3_conc_kg + 2 * CO3_conc_kg + BOH4_conc_kg + OH_conc_kg  - H_conc_kg  

        #          mol m-3         kg m-3      mol kg-1
        varsdata.H_conc[i] = density * H_conc_kg
        varsdata.OH_conc[i] = density * OH_conc_kg     
        varsdata.HCO3_conc[i] = density * HCO3_conc_kg        
        varsdata.CO3_conc[i] = density * CO3_conc_kg     
        varsdata.CO2_aq_conc[i] = density * CO2_aq_conc_kg  
        varsdata.BOH4_conc[i] = density * BOH4_conc_kg
        varsdata.BOH3_conc[i] = density * BOH3_conc_kg                                          

        #            mol m-3               mol m-3           mol kg-1          kg m-3                  
        varsdata.TAlk_error[i] = varsdata.TAlk_conc[i] - TAlk_conc_kg_calcu * density
    
    end
    

    return nothing


end



end 

# module