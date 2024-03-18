# Configurable chemistry using PALEOaqchem

These examples illustrate how to use the yaml configuration file to configure generic chemistry Reactions from PALEOaqchem
to implement the same minimal model of the marine carbonate system shown in the [Ocean chemistry](@ref) examples.

See `PALEOaqchem` [documentation](https://paleotoolkit.github.io/PALEOaqchem.jl/) for more detail on the generic aqueous chemistry.

See `PALEOmodel` [documentation](https://paleotoolkit.github.io/PALEOmodel.jl/) for more information on analysing model output.

## Example 1 Configuring a minimal Alk-pH model

This example configures generic chemistry reactions from PALEOaqchem to define a minimal Alk-pH model for aqueous carbonate chemistry. Carbonate system equations are from [Zeebe2001](@cite).

The `ocean` domain contains a [`ReactionNoTransport`](https://paleotoolkit.github.io/PALEOocean.jl/dev/PALEOocean_Reactions/#PALEOocean.Ocean.OceanNoTransport.ReactionOceanNoTransport) from the [`PALEOocean`](https://github.com/PALEOtoolkit/PALEOocean.jl) Julia package.  This defines standard ocean variables including cell `volume`, and is configured here to provide one ocean cell.

There are two state variables for `DIC` and `TAlk`, implemented using a [`ReactionReservoir`](https://paleotoolkit.github.io/PALEOboxes.jl/stable/ReactionCatalog/#PALEOboxes.Reservoirs.ReactionReservoir) from the [`PALEOboxes`](https://github.com/PALEOtoolkit/PALEOboxes.jl) Julia package. This Reaction also provides concentrations in `mol m-3`.  Constant Boron concentration `B_conc` is defined using a [`ReactionReservoirConst`](https://paleotoolkit.github.io/PALEOboxes.jl/stable/ReactionCatalog/#PALEOboxes.Reservoirs.ReactionReservoirConst).

The carbonate chemistry system includes the speciation of water, boron and DIC. `B`, `DIC`, and `TAlk` are the three total variables with corresponding primary species concentrations `BOH3_conc`, `CO2_aq_conc`, and `H_conc` (defined by `pH`). Primary species are defined using the PALEOaqchem `ReactionConstraintReservoir`, which defines a state variable  (attribute `:vfunction = PB.VF_State`) eg `BOH3_conc`, an algebraic constraint for the corresponding total eg `B_constraint_conc` (with attribute `:vfunction = PB.VF_Constraint`), and a variable eg `B_calc` to accumulate primary and secondary species contributions. Secondary species eg `BOH4` are defined using the PALEOaqchem `ReactionAqEqb`, and their contribution added to the calculated total eg `B_calc`. The PALEO DAE solver then solves for the primary species concentration `BOH3_conc` that makes `B_calc` equal to the required value `B`. Note that the `ReactionConstraintReservoir` for `TAlk` defines `pH` as the state variable (from which `H_conc` is calculated), and that many species contribute to both `TAlk_calc` and their own total.
 
The combined system is then a Differential Algebraic Equation (DAE) system with two ODE state variables and corresponding time derivatives for `DIC` and `TAlk`, three algebraic constraints for `B`, `DIC`, and `TAlk`, and three additional state variables for the primary species `BOH3_conc`, `CO2_aq_conc`, and `pH`, and is integrated forward in time by a DAE solver [`PALEOmodel.ODE.integrateDAE`](https://paleotoolkit.github.io/PALEOmodel.jl/stable/PALEOmodelSolvers/#PALEOmodel.ODE.integrateDAE).


### yaml configuration file
The model configuration (file `examples/configurable_chemistry/config_ex1.yaml`) contains two Reservoirs `DIC`, `TAlk`.

A `ReactionFluxPerturb` from the PALEOboxes.jl reaction catalog is used to add a constant TAlk flux.

```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "configurable_chemistry/config_ex1.yaml"), String))
    ```"""
)
```

### Run script
The script to run the model (file `examples/configurable_chemistry/run_ex1.jl`) contains:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "configurable_chemistry/run_ex1.jl"), String))
    ```"""
)
```
and produces output showing the change, if `TAlk_conc` increase, how the carbonic acid and pH change in ocean:
```@example ex1
include(joinpath(ENV["PALEO_EXAMPLES"], "configurable_chemistry/run_ex1.jl")) # hide
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
        (cell=1, tmodel=(1.0, 1e12)); # omit first point (pH 8 starting condition)  # hide
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

## Example 2 Minimal Alk-pH model with implicit variables

This example contains the same chemistry as [Example 1 Configuring a minimal Alk-pH model](@ref), using the Direct Substitution Approach (DSA) to eliminate the two algebraic equations corresponding to the mass action equations for `DIC` and `TAlk`.

The state variables for `DIC_conc` and `TAlk_conc` are now implicit total variables defined by PALEOaqchem `ReactionImplicitReservoir`s. These define a PALEO Total variable  (attribute `:vfunction = PB.VF_Total`) eg `DIC_conc` which is a function of a primary species concentration implemented as a PALEO StateTotal variable (attribute `:vfunction = PB.VF_StateTotal`) eg `CO_2_aq_conc`, and a time derivative eg `DIC_conc_sms` implemented as a PALEO Deriv variable (attribute `:vfunction = PB.VF_Deriv`).
 
The combined system is then a Differential Algebraic Equation (DAE) system with three implicit total variables for `DIC_conc`, `B_conc`, and `TAlk_conc`, with corresponding time derivatives `DIC_conc_sms`, `B_conc_sms`, and `TAlk_conc_sms` and state variables for the primary species `CO2_aq_conc`, `BOH3_conc` and `pH`, and is integrated forward in time by a DAE solver [`PALEOmodel.ODE.integrateDAE`](https://paleotoolkit.github.io/PALEOmodel.jl/stable/PALEOmodelSolvers/#PALEOmodel.ODE.integrateDAE).

Notes:
- The combination of constant `BOH3_conc` and a `ReactionConstraintReservoir` defining primary species `BOH3_conc` has been replaced with an implicit state variable for `B_conc` and primary species `BOH3_conc`: this is required to use the IDA DAE solver, which cannot handle initialisation of that combination of implicit and constraint variables (see `PALEOmodel` documentation).
- Initial values are now specified for the primary species (eg `CO2_conc`, `BOH3_conc`, `pH`), not the corresponding totals (eg `DIC_conc`). This is less convenient here (where we are want to set `DIC_conc` and `B_conc` that remain constant), but may not be an issue in a more complete model that includes additional processes that define  time evolution that is insensitive to initial conditions after a spinup.
- This configuration provides concentrations, instead of mol (per cell) to the solver. This is not required here, but is good practice as it helps the numerical solver by providing variables with better scaling.


### yaml configuration file
The model configuration (file `examples/configurable_chemistry/config_ex2.yaml`) contains: 

```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "configurable_chemistry/config_ex2.yaml"), String))
    ```"""
)
```

### Run script
The script to run the model (file `examples/configurable_chemistry/run_ex2.jl`) contains:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "configurable_chemistry/run_ex2.jl"), String))
    ```"""
)
```
and produces output showing the change, if `TAlk_conc` increase, how the carbonic acid and pH change in ocean:
```@example ex2
include(joinpath(ENV["PALEO_EXAMPLES"], "configurable_chemistry/run_ex2.jl")) # hide
plot(paleorun.output, ["ocean.TAlk_conc", "ocean.DIC_conc"],                                           (cell=1,); ylabel="TAlk, DIC conc (mol m-3)") # hide
savefig("ex2_plot1.svg"); nothing  # hide
plot(paleorun.output, "ocean.pH",                                                                      (cell=1,)) # hide
savefig("ex2_plot2.svg"); nothing  # hide
plot(paleorun.output, ["ocean.DIC_conc", "ocean.HCO3_conc", "ocean.CO3_conc", "ocean.CO2_aq_conc"],    (cell=1,); ylabel="DIC species (mol m-3)") # hide
savefig("ex2_plot3.svg"); nothing  # hide
display(  # hide
    plot(  # hide
        paleorun.output,   # hide
        ["ocean.HCO3_conc", "ocean.CO3_conc", "ocean.CO2_aq_conc", "ocean.BOH4_conc", "ocean.BOH3_conc",  "ocean.H_conc", "ocean.OH_conc",],  # hide
        (cell=1, tmodel=(1.0, 1e12)); # omit first point (pH 8 starting condition)  # hide
        coords=["tmodel"=>("ocean.pH",),], # plot against pH instead of tmodel  # hide
        ylabel="H2O, B, DIC species (mol m-3)", ylim=(0.5e-3, 0.5e1), yscale=:log10,  # hide
        legend_background_color=nothing,  # hide
        legend=:bottom,  # hide
    )  # hide
)  # hide
savefig("ex2_plot4.svg"); nothing  # hide
```

![](ex2_plot1.svg)
![](ex2_plot2.svg)
![](ex2_plot3.svg)
![](ex2_plot4.svg)


### Displaying model structure and variables

All metadata for model variables can be displayed with `PB.show_variables`:
```@example ex2
show(PB.show_variables(model), allcols=true, allrows=true) # display in REPL
# vscodedisplay(PB.show_variables(model)) # more convenient when using VS code
```

