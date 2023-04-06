

import PALEOboxes as PB
import PALEOmodel
import PALEOcopse

function CPU_modular_expts(expts)

    model = PB.create_model_from_config(
        joinpath(@__DIR__, "CPU_modular_cfg.yaml"), 
        "CPU_Zhang2020"; 
        modelpars=Dict(), # optional Dict can be supplied to set top-level (model wide) Parameters
    )
        
    ###############################################
    # choose an 'expt' (a delta to the base model)
    ###############################################

    for expt in expts
        if expt == "baseline"
            # baseline configuration
        elseif length(expt) == 2 && expt[1] == "LIP"
            # apply 'Witches hat' perturbation given total C input 
            LIP_total = expt[2] # mol C
            LIP_peak = 2*LIP_total/0.1e6 # mol C yr-1 at peak
            F_LIP = PB.get_reaction(model, "global", "F_LIP")
            # flux is specified as linear interpolation at 'perturb_times'
            PB.setvalue!(F_LIP.pars.perturb_times,    [-1e30, 0.1e6,  0.15e6,     0.2e6,  1e30])
            PB.setvalue!(F_LIP.pars.perturb_totals,   [0.0,   0.0,    LIP_peak,   0.0,    0.0]) 
            PB.setvalue!(F_LIP.pars.perturb_deltas,   [1.0,   1.0,    1.0,        1.0,    1.0].*-5.0)

        elseif length(expt) == 2 && expt[1] == "V"
            # change V (vegetation) forcing 
            V_new = expt[2]
            force_V = PB.get_reaction(model, "global", "force_V")
            # V is specified as linear interpolation at 'force_times'
            PB.setvalue!(force_V.pars.force_times,    [-1e30, 0.1e6,  0.2e6,     1e30])
            PB.setvalue!(force_V.pars.force_values,   [1.0,   1.0,    V_new,     V_new])

        elseif length(expt) == 2 && expt[1] == "E"
            # change E (vegetation) forcing 
            E_new = expt[2]
            force_E = PB.get_reaction(model, "global", "force_E")
            # V is specified as linear interpolation at 'force_times'
            PB.setvalue!(force_E.pars.force_times,    [-1e30, 0.1e6,  0.2e6,     1e30])
            PB.setvalue!(force_E.pars.force_values,   [1.0,   1.0,    E_new,     E_new])                                 
        else
            error("unknown expt ", expt)
        end
    end

    return model
end


function plot_CPU_modular(output; pager=PALEOmodel.DefaultPlotPager())
 
    pager(
        plot(output, "global.".*["E", "W", "V", "D"],   title="Forcings", ylabel="normalized forcing"),
        plot(output, "global.F_LIP",                    title="LIP injection", ylabel="LIP injection (mol C yr-1)"),
        plot(output, "atmocean.A",                      title="Carbon"),        
        plot(output, "atm.pCO2PAL",                     title="pCO2", ylabel="pCO2 (PAL)"),
        plot(output, "land.DeltaT",                     title="Delta T", ylabel="Temperature anomaly (K)"),
        plot(output, "ocean.f_anoxic",                  title="f_anoxic", ylabel="anoxic fraction (f_anoxic)"),
        plot(output, "ocean.P_norm",                    title="Phosphorus", ylabel="P/P_0 (normalized)"),
        plot(output, "ocean.U_norm",                    title="Uranium", ylabel="U/U_0 (normalized)"),
        plot(output, "ocean.U_delta",                   title="Uranium isotopes", ylabel="delta 238U (per mil)"),
        plot(output, ["atmocean.A_delta", "atm.CO2_delta", "ocean.DIC_delta"],  title="Carbon isotopes", ylabel="delta 13C (per mil)"),
    
        :newpage, # flush any partial page
    )
    return nothing
end
