

# CPU (Carbon, Phosphorus, Uranium)

These examples demonstrate the CPU model ([Clarkson2018](@cite), [Zhang2020](@cite)), using a minimal single-box implementation in PALEO.

## Setting the Julia environment and working directory
If it is not already active, activate the Julia environment `PALEOjulia/PALEOexamples`:

In `VS code`, right click on `PALEOjulia/PALEOexamples` or any subfolder in the file browser and select `Julia: Activate Parent Environment`. Or from the REPL, use `]` to enter package management:

    julia> pwd()
    "/home/sd336/software/julia/PALEOjulia/PALEOexamples/src/CPU"
    julia> ] activate ../..
    (PALEOexamples) pkg> activate ../..
     Activating environment at `~/software/julia/PALEOjulia/PALEOexamples/Project.toml`

Change the Julia REPL working directory to the `PALEOjulia/PALEOexamples/src/CPU` folder:

In `VS code`, right click on this folder in the file browser and select `Julia: Change to This Directory`. Or from the REPL, use the `cd` command):

    julia> cd("PALEOexamples/src/CPU")


## To run the CPU example with a default 3e18 mol C perturbation
   
    julia> include("CPU.jl")

This will run and plot output (NB: the first run will be slow as Julia JIT compiles the code).

## To display model Parameters, Variables, and output.

See `PALEOmodel` documentation.

