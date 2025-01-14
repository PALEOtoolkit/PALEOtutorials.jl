# PALEO components workflow

PALEO_components_workflow.svg with (local) fonts (will not render correctly in paper)

PALEO_components_workflow_fontpath.svg
Inkscape convert fonts to paths:
- select some text
- edit->select same -> object type
- path -> object to path

# PALEO three views

PALEO_threeviews.svg with (local) fonts (will not render correctly in paper)

PALEO_threeviews_fontpath.svg
Inkscape convert fonts to paths:
- select some text
- edit->select same -> object type
- path -> object to path

# Composite model output

## COPSE 

PALEOcopse.jl
examples/COPSE/COPSE_reloaded_reloaded.jl

gr(size=(600, 500))
plot(title="O2 charcoal", 100*PALEOmodel.get_array(run.output, "land.mrO2"), ylabel="O_2 (%)", margin=(5, :mm), xlims=(-650e6, 0))
DataCompilations.plot_O2_charcoal() # NB: PALEOdev only, data compilation not available under Open Source licence
savefig(current, "O2charcoal.svg")

## EPOC

EPOC_model

Panel C from Daines & Li (2024) Fig 5 Dynamics and stability of the coupled P, O, A system...
(local file Figure5_3D_change_regimes_20240511.svg)

## Atmosphere photochemistry

PALEOatmosphere.jl

examples/reaction_networks_eval/Archean_3_8Ga_methanogen_PIE_test0_20230902/PALEO_C2HONS_archean_biotic_lightning_solar.jl

    # gr(size=(600, 500))
gr(size=(500, 400))
plot_tracers_summary(
    paleorun.output; 
    tracers=[ "O2_mr", "H2O_mr", "H_mr", "H2_mr", "CO_mr", "CH4_mr", "C2H6_mr",  "CO2_mr", "O_mr"],       
    kwargs=(title="Atmosphere mixing ratio", xscale=:log10, xlabel="mixing ratio", xlim=(1e-11, 1.0), background_color_legend=nothing, foreground_color_legend=nothing, legend_position=:topleft),
    tmodel=1e12,
)
savefig(current(), "C2HONS_archean_biotic_mrsummary.svg")

## Atmosphere climate

PALEOatmosphere.jl

examples/socrates_climate/SOCRATES_examples_convadj_modEarth.jl

gr(size=(500, 400))
plot(title="Global mean temperature", GAM_jain2000.T_K, GAM_jain2000.P_Pa;
    swap_xy=true, yflip=true, yscale=:log10, label="Jain (2000)")
plot!(paleorun.output, "atm.tmid", (tmodel=1e12, column=1);
    coords=nothing, swap_xy=true, xlabel="temperature (K)", background_color_legend=nothing, legend=:right)
savefig(current(), "SOCRATES_convadj_modEarth_T.svg")


## MITgcm

PALEOocean.jl
examples/mitgcm/MITgcm_2deg8_PO4MMcarbSCH4.jl  (2000yr run)
examples/mitgcm/images/make_images.jl

## 1D shelf

PALEOocean.jl
examples/shelf1D/PALEO_examples_shelf1D_P_O2.jl

gr(size=(600, 500))
heatmap(title="ocean P (mol m-3)", paleorun.output, "ocean.P_conc"; margin=(7.5, :mm))
savefig(current(), "1Dshelf_P_conc.svg")
