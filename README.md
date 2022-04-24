# PALEOtutorials.jl

[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://PALEOtoolkit.github.io/PALEOtutorials.jl/dev)

Introduction and tutorials for the PALEO framework.  This repository includes minimal examples that demonstrate Julia workflows and how to use the framework to construct and use models. See eg the [PALEOcopse](https://github.com/PALEOtoolkit/PALEOcopse.jl) repository for full scientific model configurations.

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

See the online [Documentation](https://paleotoolkit.github.io/PALEOtutorials.jl/) for details.