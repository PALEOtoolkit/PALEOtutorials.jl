import PALEOboxes as PB
# import PALEOreactions
import PALEOmodel

"Test cases and examples for 1D shelf NPZ"

function NPZ_shelf_expts(
    baseconfig, expts; 
    extra_model_parameters=nothing, 
)

    if baseconfig == "P_O2"
        # P, O2 only population-based phytoplankton model

        model = PB.create_model_from_config(
            joinpath(@__DIR__, "NAPC_cfg.yaml"),
            "NP_shelf",
        )

        run = PALEOmodel.Run(model=model, output = PALEOmodel.OutputWriters.OutputMemory()) 

    elseif baseconfig == "P_O2_Z"
        # P, O2 only population-based phytoplankton model with zooplankton
    
        model = PB.create_model_from_config(
            joinpath(@__DIR__, "NAPC_cfg.yaml"),
            "NPZ_shelf",
        )
    
        run = PALEOmodel.Run(model=model, output = PALEOmodel.OutputWriters.OutputMemory()) 
    
    else
        error("unknown baseconfig ", baseconfig)
    end

    ###############################################
    # choose an 'expt' (a delta to the base model)
    ###############################################

    for expt in expts        
        println("Add expt: ", expt)
        if expt == "baseline"
            # defaults       
        else
            error("unrecognized expt='$(expt)'")
        end
    end

    return run
end