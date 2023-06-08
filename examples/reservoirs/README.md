# Reservoirs and fluxes

These examples illustrate how to code a PALEO Reaction and configure a model, working through a minimal example of
first order decay or transformation of a scalar biogeochemical reservoir ``A`` into a second reservoir ``B`` via a flux ``F``,
with equations:

```math
F = \kappa A
```
```math
\frac{dA}{dt} = - F \\
```
```math
\frac{dB}{dt} =   F \\
```

See `PALEOmodel` [documentation](https://paleotoolkit.github.io/PALEOmodel.jl/) for more information on analysing model output.

## Example 1 A minimal self-contained PALEO reaction

This is verbose as we have to (re)implement Variable setup and initialisation as well as the biogeochemical reaction of interest, but illustrates the structure of a PALEO model.

!!! info
    This verbose approach is not usually required, it is usually simpler to use predefined PALEO Reservoirs as described below, [Example 2 Using a PALEO Reservoir](@ref)

### Additional code files
The code to implement a self-contained PALEO reaction is in file `examples/reservoirs/reactions_ex1.jl`, and needs to provide three
methods for Variable setup, initialization at the start of the main loop, as well as the actual main loop do method. Variables are labelled as state Variables and derivatives by setting the `:vfunction` attribute to `VF_StateExplicit` and `VF_Deriv`.
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/reactions_ex1.jl"), String))
    ```"""
)
```

### yaml configuration file
The model configuration (file `examples/reservoirs/config_ex1.yaml`) contains just a single Reaction:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/config_ex1.yaml"), String))
    ```"""
)
```

### Run script
The script to run the model (file `examples/reservoirs/run_ex1.yaml`) contains:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/run_ex1.jl"), String))
    ```"""
)
```
And produces output:
```@example ex1
include(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/run_ex1.jl")) # hide
plot(paleorun.output, "global.A") # hide
savefig("ex1_plot1.svg")  # hide
plot(paleorun.output, "global.decay_flux")  # hide
savefig("ex1_plot2.svg"); nothing # hide
```
![](ex1_plot1.svg)
![](ex1_plot2.svg)

### Displaying model structure and variables
All metadata for model variables can be displayed with `PB.show_variables`:
```@example ex1
show(PB.show_variables(model), allcols=true, allrows=true) # display in REPL
# vscodedisplay(PB.show_variables(model)) # more convenient when using VS code
```
The `type` column shows the two pairings of `VariableReaction`s linked to `VariableDomain`s:
- Reaction Property and Dependency Variables, linked to a `VariableDomPropDep`. These are used to represent
    a quantity calculated in one Reaction (or provided by the numerical solver, in the case of "global.A") that is then used by other Reactions.
- Reaction Target and Contributor Variables, linked to a `VariableDomContribTarget`. These are used to represent
    a flux-like quantity, with one Reaction (or the numerical solver, in the case of "global.A_sms") definining the Target and multiple Reactions adding contributions.

Variable links for an individual VariableDomain can be displayed using `PB.show_links`,
where the linked variables are shown as "`<domain name>.<reaction name>.<method name>.<local name>`":
```@example ex1
PB.show_links(model, "global.decay_flux")
```
(demonstrating that `global.decay_flux` is set by the `do_example1` method of the Reaction named `Adecay` in the yaml config file)

```@example ex1
PB.show_links(model, "global.A")
```
(demonstrating that the "global.A" state Variable has both the `do_setup_example1` and `do_example1` methods of the Reaction
named `Adecay` in the yaml config file, which respectively set the initial value at model start, and then read the value at each timestep)

`PB.show_variables` with an additional `showlinks=true` argument will also show variable links:
```@example ex1
show(PB.show_variables(model; showlinks=true), allcols=true, allrows=true) # display in REPL
# vscodedisplay(PB.show_variables(model; showlinks=true)) # more convenient when using VS code
```
where the property, dependencies, target and contributor columns show the VariableReactions (defined by ReactionMethods) that
link to each VariableDomain.

### Analysing output
Numerical values of variables at each timestep can be displayed with `PB.get_table`:
```@example ex1
show(PB.get_table(paleorun.output, "global"), allcols=true, allrows=true) # display to REPL
# vscodedisplay(PB.get_table(paleorun.output, "global")) # more convenient when using VS code
```
NB: this displays Variables from the specified model Domain, for this example all Variables are in the "global" Domain.

Output for a single Variable (eg for further analysis) can be retrieved with:
```@example ex1
A = PALEOmodel.get_array(paleorun.output, "global.A")  # an xarray like object with data and coordinates
A.values  # a Vector of values at each model time
```

## Example 2 Using a PALEO Reservoir

The standard way to configure PALEO models is to use a combination of ReactionReservoirs (from the [`Reaction catalog`](https://paleotoolkit.github.io/PALEOboxes.jl/stable/ReactionCatalog/#Reservoirs) provided by the `PALEOboxes` package) to define model state Variables and provide setup and initialisation, and then link to these Variables from other Reactions.

### Additional code files
In this example, the Reaction code now only needs to implement a 'do' method (file `examples/reservoirs/reactions_ex2.jl`):
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/reactions_ex2.jl"), String))
    ```"""
)
```

### yaml configuration file
The model configuration (file `examples/reservoirs/config_ex2.yaml`) contains a `ReactionReservoirScalar` from the
generic [`Reaction catalog`](https://paleotoolkit.github.io/PALEOboxes.jl/stable/ReactionCatalog/#Reservoirs) provided by the `PALEOboxes` package:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/config_ex2.yaml"), String))
    ```"""
)
```

### Run script
The script to run the model (file `examples/reservoirs/run_ex2.jl`) contains:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/run_ex2.jl"), String))
    ```"""
)
```
and produces output:
```@example ex2
include(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/run_ex2.jl")) # hide
plot(paleorun.output, "global.A") # hide
savefig("ex2_plot1.svg")  # hide
plot(paleorun.output, "global.decay_flux")  # hide
savefig("ex2_plot2.svg"); nothing # hide
```
![](ex2_plot1.svg)
![](ex2_plot2.svg)

### Displaying model structure and variables

All metadata for model variables can be displayed with `PB.show_variables`:
```@example ex2
show(PB.show_variables(model), allcols=true, allrows=true) # display in REPL
# vscodedisplay(PB.show_variables(model)) # more convenient when using VS code
```
there is one more Variable "global.A_norm", the normalized value of "global.A", provided by the generic ReactionReservoirScalar and not used here.

The linking of the "global.A" variable illustrates the key difference between this example and Example 1:
```@example ex2
PB.show_links(model, "global.A")
```

The "global.A" state Variable now has three dependencies:
- the `setup_initialvalue_vars_default` method of the reaction named `reservoir_A` in the yaml file (a ReactionReservoirScalar), where
  the variable has local name `R` and has been renamed to `A` in the yaml file.
- the `do_reactionreservoirscalar` method of the reaction named `reservoir_A` (which calculates normalized value `A_norm`, not needed here).
- the `do_example1` method of the Reaction named `Adecay` in the yaml config file, where the variable has local name `A`, which reads the value.

## Example 3 Transfer between two Reservoirs

Generalizing the Reaction to transfer between two reservoirs.

### Additional code files
The Reaction code (file `examples/reservoirs/reactions_ex3.jl`) now produces an `output_flux`, and has been
generalized to operate on a generic `input_particle` Reservoir:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/reactions_ex3.jl"), String))
    ```"""
)
```

### yaml configuration file
The model configuration (file `examples/reservoirs/config_ex3.yaml`) contains two Reservoirs `A` and `B`, and additional configuration for `ReactionExample3` to rename the generic `input_particle` to link to Reservoir `A` and `output_flux` to link to Reservoir `B`:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/config_ex3.yaml"), String))
    ```"""
)
```

### Run script
The script to run the model (file `examples/reservoirs/run_ex3.jl`) contains:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/run_ex3.jl"), String))
    ```"""
)
```
and produces output showing the transfer between two Reservoirs:
```@example ex3
include(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/run_ex3.jl")) # hide
plot(paleorun.output, ["global.A", "global.B"]; ylabel="reservoir (mol)") # hide
savefig("ex3_plot1.svg")  # hide
plot(paleorun.output, "global.decay_flux")  # hide
savefig("ex3_plot2.svg"); nothing # hide
```
![](ex3_plot1.svg)
![](ex3_plot2.svg)

### Displaying model structure and variables

All metadata for model variables can be displayed with `PB.show_variables`:
```@example ex3
show(PB.show_variables(model), allcols=true, allrows=true) # display in REPL
# vscodedisplay(PB.show_variables(model)) # more convenient when using VS code
```
We now have additional Variables corresponding to the `B` reservoir.

## Example 4 Transfer between Domains

The `ReactionExample3` from the previous example can be reused in a different model configuration that includes flux transfer between Reservoirs in two Domains. 

### Additional code files
This example reuses the PALEO reactions from [Example 3 Transfer between two Reservoirs](@ref)
 
### yaml configuration file
The model configuration (file `examples/reservoirs/config_ex4.yaml`) contains two Domains `Box1` and `Box2`,
and a flux coupler Domain `fluxBoxes`.  The `ReactionSum` in the `global` Domain tracks conservation:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/config_ex4.yaml"), String))
    ```"""
)
```

### Run script
The script to run the model (file `examples/reservoirs/run_ex4.jl`) contains:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/run_ex4.jl"), String))
    ```"""
)
```
and produces output showing the transfer between two Reservoirs in different Domains via the fluxBoxes flux coupler:
```@example ex4
include(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/run_ex4.jl")) # hide
plot(paleorun.output,  ["Box1.A", "Box2.B", "global.E_total"]; ylabel="reservoir (mol)") # hide
savefig("ex4_plot1.svg")  # hide
plot(paleorun.output, ["Box1.decay_flux", "fluxBoxes.flux_B"]; ylabel="flux (mol yr-1)")  # hide
savefig("ex4_plot2.svg"); nothing # hide
```
![](ex4_plot1.svg)
![](ex4_plot2.svg)

### Displaying model structure and variables

All metadata for model variables can be displayed with `PB.show_variables`:
```@example ex4
show(PB.show_variables(model), allcols=true, allrows=true) # display in REPL
# vscodedisplay(PB.show_variables(model)) # more convenient when using VS code
```
This shows that we now have four Domains:
- `Box1` containing `reservoir_A`, `Adecay`, and associated Variables
- `Box2` containing `reservoir_B`and associated Variables
- `fluxBoxes` containing a Variable `flux_B` created by the `ReactionFluxTarget`
- `global` containing `E_total` to check conservation.

### An aside on ordering of ReactionMethods
!!! info
    It is rarely necessary or useful to look at this - shown here just to illustrate how PALEO works

PALEO orders ReactionMethods based on the dependency information defined by the linked Variables
(a method defining a Property must run before all methods that link to it as Dependencies, a method
defining a Target must run after all methods that link to it as Contributors).

The order in which ReactionMethods are called during each timestep is stored in `model.sorted_methods_do` (a `struct PB.MethodSort`) and can be displayed using:
```@example ex4
model.sorted_methods_do
```
Each group of methods has no internal dependencies, but depends on methods
in previous groups.  Here there is only one dependency, method `Box2.transfer_fluxBoxes.do_transfer`
must run after the decay flux is calculated by `Box1.reservoir_A.do_reactionreservoirscalar`.

## Example 5 Isotopes and Rayleigh fractionation

PALEO Variables can represent isotopes by setting the `:field_data` Attribute. Currently `IsotopeLinear` is supported,
which represents a linearized approximation to a single isotope using two components `total` and `total x delta`.  Standard
arithmetic (additon/subtraction, multiplication by a scalar) is supported.

### Additional code files
The Reaction code (file `examples/reservoirs/reactions_ex5.jl`) now requires additional Parameters `field_data` to set the
data type, and `Delta` to set the fractionation assumed to occur during the decay/transfer. 
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/reactions_ex5.jl"), String))
    ```"""
)
```

### yaml configuration file
The model configuration (file `examples/reservoirs/config_ex5.yaml`) contains a global parameter `EIsotope`
used to set the isotope Type for all Reactions affecting the hypothetical element `E`.
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/config_ex5.yaml"), String))
    ```"""
)
```

### Run script
The script to run the model (file `examples/reservoirs/run_ex5.jl`) contains:
```@eval
import Markdown
Markdown.parse(
    """```julia
    $(read(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/run_ex5.jl"), String))
    ```"""
)
```
and produces output showing Rayleigh fractionation:
```@example ex5
include(joinpath(ENV["PALEO_EXAMPLES"], "reservoirs/run_ex5.jl")) # hide
plot(paleorun.output,  ["Box1.A", "Box2.B", "global.E_total"]; ylabel="reservoir (mol)") # hide
savefig("ex5_plot1.svg")  # hide
plot(paleorun.output, ["Box1.decay_flux", "fluxBoxes.flux_B"]; ylabel="flux (mol yr-1)")  # hide
savefig("ex5_plot2.svg"); nothing # hide
plot(paleorun.output, ["Box1.A_delta", "Box1.decay_flux.v_delta", "Box2.B_delta", "global.E_total.v_delta", ]; ylabel="delta (per mil)") # hide
savefig("ex5_plot3.svg"); nothing # hide
```

![](ex5_plot1.svg)
![](ex5_plot2.svg)
![](ex5_plot3.svg)

### Displaying model structure and variables

All metadata for model variables can be displayed with `PB.show_variables`:
```@example ex5
show(PB.show_variables(model), allcols=true, allrows=true) # display in REPL
# vscodedisplay(PB.show_variables(model)) # more convenient when using VS code
```
The variable names are as in [Example 4 Transfer between Domains](@ref), however `field_data`
is now `IsotopeLinear` and not `ScalarData` for the reservoir and flux variables.

