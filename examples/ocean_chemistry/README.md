# Ocean chemistry

These examples illustrate how to implement:
- a minimal model of the marine carbonate system
- air-sea exchange of CO2 between ocean and atmosphere Domains

See `PALEOmodel` [documentation](https://paleotoolkit.github.io/PALEOmodel.jl/) for more information on analysing model output.

## Example 1 Minimal Alk-pH model

This example implements a new `Reaction_Alk_pH` to establish a minimal Alk-pH model for aqueous carbonate chemistry. Carbonate system equations are from [Zeebe2001](@cite).

The `ocean` domain contains a [`ReactionNoTransport`](https://paleotoolkit.github.io/PALEOocean.jl/dev/PALEOocean_Reactions/#PALEOocean.Ocean.OceanNoTransport.ReactionOceanNoTransport) from the [`PALEOocean`](https://github.com/PALEOtoolkit/PALEOocean.jl) Julia package.  This defines standard ocean variables including cell `volume`, and is configured here to provide one ocean cell.

There are two state variables for `DIC` and `TAlk`, implemented using a [`ReactionReservoir`](https://paleotoolkit.github.io/PALEOboxes.jl/stable/ReactionCatalog/#PALEOboxes.Reservoirs.ReactionReservoir) from the [`PALEOboxes`](https://github.com/PALEOtoolkit/PALEOboxes.jl) Julia package. This Reaction also provides concentrations in `mol m-3`.

The carbonate chemistry system is solved as an algebraic constraint, calculating `TAlk_calcu` as a function of `pH` and then using a PALEO solver to solve for the `pH` value that makes `TAlk_calcu` equal to the required value. In PALEO this is implemented by defining `pH` as a `VarState` (attribute `:vfunction = PB.VF_State`) and the algebraic constraint `TAlk_error` as a `VarConstraint` (with attribute `:vfunction = PB.VF_Constraint`). The combined system of `TAlk` and `DIC` reservoirs and `pH` is then a Differential Algebraic Equation (DAE) with two state variables and one algebraic constraint, and is integrated forward in time by a DAE solver [`PALEOmodel.ODE.integrateDAE`](https://paleotoolkit.github.io/PALEOmodel.jl/stable/PALEOmodelSolvers/#PALEOmodel.ODE.integrateDAE).

### Additional code files
The Reaction code (`Reaction_Alk_pH` in file `examples/ocean_chemistry/reactions_Alk_pH.jl`) now produces calculation of different carbon species `HCO3_conc`, `CO3_conc`, `CO2_aq_conc`, boron species `BOH4_conc`, water species `H_conc` and `OH_conc` given `DIC_conc`, `TAlk_conc` and `pH`. Difference from required alkalinity `TAlk_error` is then calculated and labelled as an algebraic constraint. Note that there is loop over ocean cells to support arbitrary ocean models:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "ocean_chemistry/reactions_Alk_pH.jl"), String))
    ```"""
)
```

Documentation (generated by the Julia docstring) reads:
```@meta
CurrentModule = Min_Alk_pH
```
```@docs
Reaction_Alk_pH
```

### yaml configuration file
The model configuration (file `examples/ocean_chemistry/config_ex1.yaml`) contains two Reservoirs `DIC`, `TAlk`.
A `ReactionFluxPerturb` from the PALEOboxes.jl reaction catalog is used to add a constant TAlk flux.
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "ocean_chemistry/config_ex1.yaml"), String))
    ```"""
)
```

### Run script
The script to run the model (file `examples/ocean_chemistry/run_ex1.jl`) contains:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "ocean_chemistry/run_ex1.jl"), String))
    ```"""
)
```
and produces output showing the change, if `TAlk_conc` increase, how the carbonic acid and pH change in ocean:
```@example ex1
include(joinpath(ENV["PALEO_EXAMPLES"], "ocean_chemistry/run_ex1.jl")) # hide
plot(paleorun.output, ["ocean.TAlk_conc", "ocean.DIC_conc"],                                           (cell=1,); ylabel="TAlk, DIC conc (mol m-3)") # hide
savefig("ex1_plot1.svg"); nothing  # hide
plot(paleorun.output, "ocean.pH",                                                                      (cell=1,)) # hide
savefig("ex1_plot2.svg"); nothing  # hide
plot(paleorun.output, ["ocean.DIC_conc", "ocean.HCO3_conc", "ocean.CO3_conc", "ocean.CO2_aq_conc"],    (cell=1,); ylabel="DIC species (mol m-3)") # hide
savefig("ex1_plot3.svg"); nothing  # hide
display(  # hide
    plot(  # hide
        paleorun.output,   # hide
        ["ocean.HCO3_conc", "ocean.CO3_conc", "ocean.CO2_aq_conc", "ocean.BOH4_conc", "ocean.BOH3_conc",  "ocean.H_conc", "ocean.OH_conc",],  # hide
        (cell=1, ); # hide
        coords=["tmodel"=>("ocean.pH",),], # plot against pH instead of tmodel  # hide
        ylabel="H2O, B, DIC species (mol m-3)", ylim=(0.5e-3, 0.5e1), yscale=:log10,  # hide
        legend_background_color=nothing,  # hide
        legend=:bottom,  # hide
    )  # hide
)  # hide
savefig("ex1_plot4.svg"); nothing  # hide
```

![](ex1_plot1.svg)
![](ex1_plot2.svg)
![](ex1_plot3.svg)
![](ex1_plot4.svg)


### Displaying model structure and variables

All metadata for model variables can be displayed with `PB.show_variables`:
```@example ex1
show(PB.show_variables(model), allcols=true, allrows=true) # display in REPL
# vscodedisplay(PB.show_variables(model)) # more convenient when using VS code
```

## Example 2 Air-sea exchange

This example adds air-sea exchange of CO2 to [Example 1 Minimal Alk-pH model](@ref).

This configuration adds an atmosphere Domain `atm` with a state variable for atmospheric CO2. Following the standard PALEO convention for [`coupling spatial Domains`](https://paleotoolkit.github.io/PALEOboxes.jl/stable/DesignOverview/#Coupling-Spatial-Domains), air-sea exchange is implemented by a combination of the new reaction `Reaction_Min_AirSeaExchange` in the `oceansurface` Domain, a [`ReactionFluxTarget`](https://paleotoolkit.github.io/PALEOboxes.jl/stable/ReactionCatalog/#PALEOboxes.Fluxes.ReactionFluxTarget) in a `fluxAtmtoOceansurface` Domain to store the calculated flux, and a pair of [`ReactionFluxTransfer`s](https://paleotoolkit.github.io/PALEOboxes.jl/stable/ReactionCatalog/#PALEOboxes.Fluxes.ReactionFluxTransfer) to apply the calculated fluxes to the atmosphere CO2 and ocean DIC reservoirs. NB: the `ocean.oceansurface` subdomain represents the subset of ocean cells adjacent to the surface, and contains the same number of cells as the `oceansurface` and `fluxAtmtoOceansurface` Domains, with a 1-1 correspondence.

### Additional code files

In order to evaluate the CO2 flux change between air and sea, we add a file (file `examples/ocean_chemistry/reactions_AirSeaExchange.jl`) that implements a `Reaction_Min_AirSeaExchange` to calculate air-sea CO2 exchange following Henry's Law. NB: the reaction is implemented for a generic gas `X` that is then linked to the CO2 and DIC variables using the `variable_links:` section in the .yaml configuration file.
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "ocean_chemistry/reactions_AirSeaExchange.jl"), String))
    ```"""
)
```

Documentation (generated by the Julia docstring) reads:
```@meta
CurrentModule = Min_AirSeaExchange
```
```@docs
Reaction_Min_AirSeaExchange
```

### yaml configuration file
The model configuration (file `examples/ocean_chemistry/config_ex2.yaml`) contains three Reservoirs `DIC`, `TAlk` and `CO2`. Following `reservoirs` [Example 4 Transfer between Domains](@ref), we use `ReactionFluxTarget` and `ReactionFluxTransfer` to transfer `CO2_airsea_exchange` between `DIC` reservoir and `CO2` reservoir:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "ocean_chemistry/config_ex2.yaml"), String))
    ```"""
)
```

### Run script
The script to run the model (file `examples/ocean_chemistry/run_ex2.jl`) contains:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "ocean_chemistry/run_ex2.jl"), String))
    ```"""
)
```
and produces output showing the change, if `TAlk_conc` increase, how the carbonic acid and pH change in ocean and CO2 change in the air:
```@example ex2
include(joinpath(ENV["PALEO_EXAMPLES"], "ocean_chemistry/run_ex2.jl")) # hide
plot(paleorun.output, ["ocean.TAlk_conc", "ocean.DIC_conc"],                                           (cell=1,); ylabel="TAlk, DIC conc (mol m-3)") # hide
savefig("ex2_plot1.svg"); nothing  # hide
plot(paleorun.output, "ocean.pH",                                                                      (cell=1,)) # hide
savefig("ex2_plot2.svg"); nothing  # hide
plot(paleorun.output, ["ocean.DIC_conc", "ocean.HCO3_conc", "ocean.CO3_conc", "ocean.CO2_aq_conc"],    (cell=1,); ylabel="DIC species (mol m-3)") # hide
savefig("ex2_plot3.svg"); nothing  # hide
display(plot(paleorun.output, "atm.pCO2atm",                                                                   ))  # hide
savefig("ex2_plot4.svg"); nothing  # hide
display(plot(paleorun.output, ["global.C_total", "atm.CO2", "ocean.DIC_total"]                                  ; ylabel="atm-ocean carbon (mol)"))
savefig("ex2_plot5.svg"); nothing  # hide
```

![](ex2_plot1.svg)
![](ex2_plot2.svg)
![](ex2_plot3.svg)
![](ex2_plot4.svg)
![](ex2_plot5.svg)

### Displaying model structure and variables

All metadata for model variables can be displayed with `PB.show_variables`:
```@example ex2
show(PB.show_variables(model), allcols=true, allrows=true) # display in REPL
# vscodedisplay(PB.show_variables(model)) # more convenient when using VS code
```

## Example 3 Minimal modern earth ocean-air 

This example shows how ocean(TAlk-DIC)-air(CO2) exchange in modern state [Example 3 Minimal modern earth ocean-air](@ref).

This configuration .yaml file is the same as `Example 2 Air-sea exchange`. What is different is that we set `TAlk`, `DIC` and `K_0` to be modern state value (from [SarmientoGruber2006](@cite)) using [`PB.set_parameter_value!`](https://paleotoolkit.github.io/PALEOboxes.jl/stable/Solver%20API/#PALEOboxes.set_parameter_value!) and [`PB.set_variable_attribute!`](https://paleotoolkit.github.io/PALEOboxes.jl/stable/Solver%20API/#PALEOboxes.set_variable_attribute!)

NB: this is not an accurate model for the modern system ! See [PALEOocean.jl](https://github.com/PALEOtoolkit/PALEOocean.jl) for more complete models,
including representations of ocean spatial structure and circulation, and more detailed parameterisations of carbonate chemistry ([ReactionCO2SYS](https://paleotoolkit.github.io/PALEOaqchem.jl/dev/PALEOaqchem%20Reactions/#PALEOaqchem.CarbChem.ReactionCO2SYS)) and air-sea exchange ([ReactionAirSeaCO2](https://paleotoolkit.github.io/PALEOocean.jl/dev/PALEOocean_Reactions/#PALEOocean.Oceansurface.AirSeaExchange.ReactionAirSeaCO2))

### Run script
The script to run the model (file `examples/ocean_chemistry/run_ex3.jl`) contains:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "ocean_chemistry/run_ex3.jl"), String))
    ```"""
)
```
and produces output showing an approximate modern steady state:
```@example ex3
include(joinpath(ENV["PALEO_EXAMPLES"], "ocean_chemistry/run_ex3.jl")) # hide
plot(paleorun.output, ["ocean.TAlk_conc", "ocean.DIC_conc"],                                           (cell=1,); ylabel="TAlk, DIC conc (mol m-3)") # hide
savefig("ex3_plot1.svg"); nothing  # hide
plot(paleorun.output, "ocean.pH",                                                                      (cell=1,)) # hide
savefig("ex3_plot2.svg"); nothing  # hide
plot(paleorun.output, ["ocean.DIC_conc", "ocean.HCO3_conc", "ocean.CO3_conc", "ocean.CO2_aq_conc"],    (cell=1,); ylabel="DIC species (mol m-3)") # hide
savefig("ex3_plot3.svg"); nothing  # hide
display(plot(paleorun.output, "atm.pCO2atm",                                                                   ))  # hide
savefig("ex3_plot4.svg"); nothing  # hide
display(plot(paleorun.output, ["global.C_total", "atm.CO2", "ocean.DIC_total"]                                  ; ylabel="atm-ocean carbon (mol)"))
savefig("ex3_plot5.svg"); nothing  # hide
```

![](ex3_plot1.svg)
![](ex3_plot2.svg)
![](ex3_plot3.svg)
![](ex3_plot4.svg)
![](ex3_plot5.svg)


For more information and cooperation, please communicate with us!