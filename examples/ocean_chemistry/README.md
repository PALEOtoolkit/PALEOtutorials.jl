# Ocean chemistry

These examples illustrate how to implement:
- a minimal model of the marine carbonate system
- air-sea exchange of CO2 between ocean and atmosphere Domains

See `PALEOmodel` [documentation](https://paleotoolkit.github.io/PALEOmodel.jl/) for more information on analysing model output.

## Example 1 Minimal Alk-pH model

Generalizing the Reaction to establish a minimal Alk-pH model. Math equations are from Richard E. Zeebe's book(2001).

### Additional code files
The Reaction code (file `examples/ocean_chemistry/reactions_Alk_pH.jl`) now produces calculation of different carbonic acid  `HCO3_conc`, `CO3_conc`, `CO2_aq_conc`, and coeval concentrations change of `BOH4_conc`, `H_conc`, `OH_conc`, `DIC_conc` and `TAlk_conc`:
```@eval
str = read("../../../../examples/ocean_chemistry/reactions_Alk_pH.jl", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

### yaml configuration file
The model configuration (file `examples/ocean_chemistry/config_ex1.yaml`) contains two Reservoirs `DIC`, `TAlk`.
A `ReactionFluxPerturb` from the PALEOboxes.jl reaction catalog is used to add a constant TAlk flux.
```@eval
str = read("../../../../examples/ocean_chemistry/config_ex1.yaml", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

### Run script
The script to run the model (file `examples/ocean_chemistry/run_ex1.jl`) contains:
```@eval
str = read("../../../../examples/ocean_chemistry/run_ex1.jl", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```
and produces output showing the change, if `TAlk_conc` increase, how the carbonic acid and pH change in ocean:
```@example ex1
include("../../../../examples/ocean_chemistry/run_ex1.jl") # hide
plot(paleorun.output, ["ocean.TAlk_conc", "ocean.DIC_conc"],                                           (cell=1,); ylabel="TAlk, DIC conc (mol m-3)") # hide
savefig("ex1_plot1.svg"); nothing  # hide
plot(paleorun.output, "ocean.pH",                                                                      (cell=1,)) # hide
savefig("ex1_plot2.svg"); nothing  # hide
plot(paleorun.output, ["ocean.DIC_conc", "ocean.HCO3_conc", "ocean.CO3_conc", "ocean.CO2_aq_conc"],    (cell=1,); ylabel="DIC species (mol m-3)") # hide
savefig("ex1_plot3.svg"); nothing  # hide
```

![](ex1_plot1.svg)
![](ex1_plot2.svg)
![](ex1_plot3.svg)


### Displaying model structure and variables

All metadata for model variables can be displayed with `PB.show_variables`:
```@example ex1
show(PB.show_variables(model), allcols=true, allrows=true) # display in REPL
# vscodedisplay(PB.show_variables(model)) # more convenient when using VS code
```

## Example 2 Air-sea exchange

Adds air-sea exchange of CO2 to Example 1

### Additional code files

In order to evaluate the CO2 flux change between air and sea, we add a file (file `examples/ocean_chemistry/reactions_AirSeaExchange.jl`) to achieve air-sea CO2 exchange following Henry's Law.
```@eval
str = read("../../../../examples/ocean_chemistry/reactions_AirSeaExchange.jl", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

### yaml configuration file
The model configuration (file `examples/ocean_chemistry/config_ex2.yaml`) contains three Reservoirs `DIC`, `TAlk` and `CO2`. Following `reservoirs` [Example 4 Transfer between Domains](@ref), we use `ReactionFluxTarget` and `ReactionFluxTransfer` to transfer `CO2_airsea_exchange` between `DIC` reservoir and `CO2` reservoir:
```@eval
str = read("../../../../examples/ocean_chemistry/config_ex2.yaml", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

### Run script
The script to run the model (file `examples/ocean_chemistry/run_ex2.jl`) contains:
```@eval
str = read("../../../../examples/ocean_chemistry/run_ex2.jl", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```
and produces output showing the change, if `TAlk_conc` increase, how the carbonic acid and pH change in ocean and CO2 change in the air:
```@example ex2
include("../../../../examples/ocean_chemistry/run_ex2.jl") # hide
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

For more information and cooperation, please communicate with us!