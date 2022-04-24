# Reservoirs and fluxes

These examples illustrate how to code a PALEO Reaction and configure a model, working through a minimal example of
first order decay of a scalar biogeochemical reservoir.

## Example 1 A minimal self-contained PALEO reaction

This is verbose as we have to (re)implement Variable setup and initialisation as well as the biogeochemical reaction of interest, but illustrates the structure of a PALEO model.

The code to implement a self-contained PALEO reaction is in file `examples/reservoirs/reactions_ex1.jl`, and needs to provide three
methods for Variable setup, initialization at the start of the main loop, as well as the actual main loop do method. Variables are labelled as state Variables and derivatives by setting the `:vfunction` attribute to `VF_StateExplicit` and `VF_Deriv`.
```@eval
str = read("../../examples/reservoirs/reactions_ex1.jl", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

The model configuration (file `examples/reservoirs/config_ex1.yaml`) contains just a single Reaction:
```@eval
str = read("../../examples/reservoirs/config_ex1.yaml", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

The script to run the model (file `examples/reservoirs/run_ex1.yaml`) contains:
```@eval
str = read("../../examples/reservoirs/run_ex1.jl", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```
And produces output:
```@example ex1
include("../../examples/reservoirs/run_ex1.jl") # hide
plot(run.output, "global.A") # hide
savefig("ex1_plot1.svg")  # hide
plot(run.output, "global.decay_flux")  # hide
savefig("ex1_plot2.svg"); nothing # hide
```
![](ex1_plot1.svg)
![](ex1_plot2.svg)

## Example 2 Using a PALEO Reservoir

The standard way to configure PALEO models is to use a combination of ReactionReservoirs (from the [`Reaction catalog`](https://paleotoolkit.github.io/PALEOboxes.jl/stable/ReactionCatalog/#Reservoirs) provided by the `PALEOboxes` package) to define model state Variables and provide setup and initialisation, and then link to these Variables from other Reactions.

In this example, the Reaction code now only needs to implement a 'do' method (file `examples/reservoirs/reactions_ex2.jl`):
```@eval
str = read("../../examples/reservoirs/reactions_ex2.jl", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

The model configuration (file `examples/reservoirs/config_ex2.yaml`) contains a `ReactionReservoirScalar` from the
generic [`Reaction catalog`](https://paleotoolkit.github.io/PALEOboxes.jl/stable/ReactionCatalog/#Reservoirs) provided by the `PALEOboxes` package:
```@eval
str = read("../../examples/reservoirs/config_ex2.yaml", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

The script to run the model (file `examples/reservoirs/run_ex2.jl`) contains:
```@eval
str = read("../../examples/reservoirs/run_ex2.jl", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```
and produces output:
```@example ex2
include("../../examples/reservoirs/run_ex2.jl") # hide
plot(run.output, "global.A") # hide
savefig("ex2_plot1.svg")  # hide
plot(run.output, "global.decay_flux")  # hide
savefig("ex2_plot2.svg"); nothing # hide
```
![](ex2_plot1.svg)
![](ex2_plot2.svg)

## Example 3 Transfer between two Reservoirs

Generalizing the Reaction to transfer between two reservoirs.

The Reaction code (file `examples/reservoirs/reactions_ex3.jl`) now produces an `output_flux`, and has been
generalized to operate on a generic `input_particle` Reservoir:
```@eval
str = read("../../examples/reservoirs/reactions_ex3.jl", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

The model configuration (file `examples/reservoirs/config_ex3.yaml`) contains two Reservoirs `A` and `B`, and additional configuration for `ReactionExample3` to rename the generic `input_particle` to link to Reservoir `A` and `output_flux` to link to Reservoir `B`:
```@eval
str = read("../../examples/reservoirs/config_ex3.yaml", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

The script to run the model (file `examples/reservoirs/run_ex3.jl`) contains:
```@eval
str = read("../../examples/reservoirs/run_ex3.jl", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```
and produces output showing the transfer between two Reservoirs:
```@example ex3
include("../../examples/reservoirs/run_ex3.jl") # hide
plot(run.output, ["global.A", "global.B"]) # hide
savefig("ex3_plot1.svg")  # hide
plot(run.output, "global.decay_flux")  # hide
savefig("ex3_plot2.svg"); nothing # hide
```
![](ex3_plot1.svg)
![](ex3_plot2.svg)


## Example 4 Transfer between Domains

The `ReactionExample3` from the previous example can be reused in a different model configuration that includes flux transfer between Reservoirs in two Domains. 

The model configuration (file `examples/reservoirs/config_ex4.yaml`) contains two Domains `Box1` and `Box2`,
and a flux coupler Domain `fluxBoxes`.  The `ReactionSum` in the `global` Domain tracks conservation:
```@eval
str = read("../../examples/reservoirs/config_ex4.yaml", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

The script to run the model (file `examples/reservoirs/run_ex4.jl`) contains:
```@eval
str = read("../../examples/reservoirs/run_ex4.jl", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```
and produces output showing the transfer between two Reservoirs in different Domains via the fluxBoxes flux coupler:
```@example ex4
include("../../examples/reservoirs/run_ex4.jl") # hide
plot(run.output,  ["Box1.A", "Box2.B", "global.E_total"]) # hide
savefig("ex4_plot1.svg")  # hide
plot(run.output, ["Box1.decay_flux", "fluxBoxes.flux_B"])  # hide
savefig("ex4_plot2.svg"); nothing # hide
```
![](ex4_plot1.svg)
![](ex4_plot2.svg)


## Example 5 Isotopes and Rayleigh fractionation

PALEO Variables can represent isotopes by setting the `:field_data` Attribute. Currently `IsotopeLinear` is supported,
which represents a linearized approximation to a single isotope using two components `total` and `total x delta`.  Standard
arithmetic (additon/subtraction, multiplication by a scalar) is supported.

The Reaction code (file `examples/reservoirs/reactions_ex5.jl`) now requires additional Parameters `field_data` to set the
data type, and `Delta` to set the fractionation assumed to occur during the decay/transfer. 
```@eval
str = read("../../examples/reservoirs/reactions_ex5.jl", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

The model configuration (file `examples/reservoirs/config_ex5.yaml`) contains a global parameter `EIsotope`
used to set the isotope Type for all Reactions affecting the hypothetical element `E`.
```@eval
str = read("../../examples/reservoirs/config_ex5.yaml", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

The script to run the model (file `examples/reservoirs/run_ex5.jl`) contains:
```@eval
str = read("../../examples/reservoirs/run_ex5.jl", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```
and produces output showing Rayleigh fractionation:
```@example ex5
include("../../examples/reservoirs/run_ex5.jl") # hide
plot(run.output,  ["Box1.A", "Box2.B", "global.E_total"]) # hide
savefig("ex5_plot1.svg")  # hide
plot(run.output, ["Box1.decay_flux", "fluxBoxes.flux_B"])  # hide
savefig("ex5_plot2.svg"); nothing # hide
plot(run.output, ["Box1.A_delta", "Box1.decay_flux.v_delta", "Box2.B_delta", "global.E_total.v_delta", ]; ylabel="delta (per mil)") # hide
savefig("ex5_plot3.svg"); nothing # hide
```

![](ex5_plot1.svg)
![](ex5_plot2.svg)
![](ex5_plot3.svg)
