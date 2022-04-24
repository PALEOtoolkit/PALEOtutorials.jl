# CPU (Carbon, Phosphorus, Uranium) model

These examples demonstrate the CPU model ([Clarkson2018](@cite)) using a minimal single-box implementation in PALEO with parameter values from ([Zhang2020](@cite)).

## Setting the Julia environment and working directory
Change the Julia REPL working directory to the `PALEOtutorials/examples/CPU` folder:

In `VS code`, right click on this folder in the file browser and select `Julia: Change to This Directory`. Or from the REPL, use the `cd` command):

    julia> cd("PALEOtutorials/examples/CPU")

If it is not already active, activate the Julia environment `PALEOtutorials/examples`:

In `VS code`, right click on `PALEOtutorials/examples` or any subfolder in the file browser and select `Julia: Activate Parent Environment`. Or from the REPL, use `]` to enter package management:

    julia> pwd()
    "/home/sd336/software/julia/PALEOtutorials/examples/CPU"
    julia> ] 
    (@v1.7) pkg> activate ../
      Activating project at `/home/sd336/software/julia/PALEOtutorials/examples`
 
## To run the CPU example with a default 3e18 mol C perturbation
   
    julia> include("CPU.jl")

This will run and plot output (NB: the first run will be slow as Julia JIT compiles the code).

## To display model Parameters, Variables, and output.

See `PALEOmodel` [documentation](https://paleotoolkit.github.io/PALEOmodel.jl/)

