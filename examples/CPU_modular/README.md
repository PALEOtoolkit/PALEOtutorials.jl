# CPU (Carbon, Phosphorus, Uranium) model

These examples demonstrate the CPU model ([Clarkson2018](@cite)) using a modularised configuration in PALEO with parameter values from ([Zhang2020](@cite)).

The model configuration now contains `atm`, `land`, `ocean` Domains in addition to a `global` Domain.  The CPU model itself is split into two pieces, a `ReactionLandCPU` and `ReactionOceanCPU`, connected by fluxes in Domains `fluxRtoOcean` (for `P`, `U`, `DIC`, `TAlk`) and `fluxAtoLand` (for `CO2`).  The `A` reservoir (combined atmosphere and ocean carbon) is placed in an `atmocean` Domain and configured to calculate `CO2_delta` and `DIC_delta` in addition to partitioning of carbon between atmosphere and ocean, with atmosphere `CO2_sms` and ocean `DIC_sms` fluxes rerouted to `A_sms` using `variable_links` in the .yaml file.

## Setting the Julia environment and working directory
Change the Julia REPL working directory to the `PALEOtutorials/examples/CPU_modular` folder:

In `VS code`, right click on this folder in the file browser and select `Julia: Change to This Directory`. Or from the REPL, use the `cd` command):

    julia> cd("PALEOtutorials/examples/CPU")

If it is not already active, activate the Julia environment `PALEOtutorials/examples`:

In `VS code`, right click on `PALEOtutorials/examples` or any subfolder in the file browser and select `Julia: Activate Parent Environment`. Or from the REPL, use `]` to enter package management:

    julia> pwd()
    "/home/sd336/software/julia/PALEOtutorials/examples/CPU_modular"
    julia> ] 
    (@v1.7) pkg> activate ../
      Activating project at `/home/sd336/software/julia/PALEOtutorials/examples`
 
## To run the modular CPU example with a default 3e18 mol C perturbation
   
    julia> include("CPU_modular_examples.jl")

This will run and plot output (NB: the first run will be slow as Julia JIT compiles the code).

## To display model Parameters, Variables, and output.

See [Displaying model configuration and output from the Julia REPL](@ref) 

