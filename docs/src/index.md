# PALEOtutorials.jl documentation

Introduction and tutorials for the PALEO framework.  This repository includes minimal examples and small models that demonstrate Julia workflows and how to use the framework to construct and use models. 

For furher information, see the documentation for other  PALEO components:
- [PALEOboxes](https://github.com/PALEOtoolkit/PALEOboxes.jl) [documentation](https://paleotoolkit.github.io/PALEOboxes.jl), the PALEO framework model coupler.
- [PALEOmodel](https://github.com/PALEOtoolkit/PALEOmodel.jl) [documentation](https://paleotoolkit.github.io/PALEOmodel.jl) solvers for standalone models.
- [PALEOcopse](https://github.com/PALEOtoolkit/PALEOcopse.jl) [documentation](https://paleotoolkit.github.io/PALEOcopse.jl) an example of a larger model configuration.

## Installation

Quickstart assuming a working Julia installation (version 1.6 or later):

Clone this github repository to local directory `PALEOtutorials`: from a linux bash prompt or a Windows terminal,

    $ git clone https://github.com/PALEOtoolkit/PALEOtutorials.jl PALEOtutorials

Start julia and navigate to the `PALEOtutorials/examples` folder, and run:

    julia> import Pkg; Pkg.activate("."); Pkg.instantiate()   # download Julia packages

For details of Julia installation and setup, see the [Documentation](https://paleotoolkit.github.io/PALEOtutorials.jl/dev/ExampleInstallConfig/)

## Running the examples

Start julia and navigate to the `PALEOtutorials/examples` folder, and run:

    julia> import Pkg; Pkg.activate(".")   # activate the Julia environment

Individual examples can then be run by eg

    julia> cd("CPU")  # PALEOtutorials/examples/CPU
    julia> include("CPU_examples.jl")  # run CPU model example
