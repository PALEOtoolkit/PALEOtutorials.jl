# Installation and getting started

## Quickstart assuming a working Julia and VS code installation 

> **Note** 
> PALEO requires Julia version 1.10 or later

Clone this github repository to local directory `PALEOtutorials.jl`: from a VS code terminal, linux bash prompt or a Windows terminal,

    $ git clone https://github.com/PALEOtoolkit/PALEOtutorials.jl

Start VS code and the julia REPL, activate the `PALEOtutorials.jl/examples` environement:
- In `VS code`, right click on any file in the `PALEOtutorials.jl/examples` folder and select `Julia: activate parent environment` from the pop-up menu. 

navigate to the `PALEOtutorials.jl/examples` folder, and run:

    julia> import Pkg
    julia> Pkg.instantiate()   # download Julia packages

Individual examples can then be run by eg

    julia> cd("CPU")  # PALEOtutorials.jl/examples/CPU
    julia> include("CPU_examples.jl")  # run CPU model example

See the online [Documentation](https://paleotoolkit.github.io/PALEOtutorials.jl/) for details.

## Installing and configuring Julia, VS Code, and PALEOtutorials.jl

### Install Julia
Download and install Julia from <https://julialang.org/downloads/> (PALEO requires Julia 1.10 or a later version).

### Install VS Code
Install VS Code from <https://code.visualstudio.com/download>
Follow instructions at <https://github.com/julia-vscode/julia-vscode> to install the Julia extension.

### Clone the PALEOtutorials.jl github repository
This will download <https://github.com/PALEOtoolkit/PALEOtutorials.jl> into a new folder `PALEOtutorials.jl`

    git clone https://github.com/PALEOtoolkit/PALEOtutorials.jl


### Start a Julia REPL in VS code

Launch VScode from the `PALEOtutorials.jl` folder, or use `Menu->File->Open folder` from inside VSCode to change to this folder.

Start Julia REPL: 
- click VScode menu `View -> Command Palette`, search for Julia, select `Julia: Start REPL` 

### Activate the `PALEOtutorials.jl/examples` Julia environment and install Julia packages

The majority of high-level Julia functionality (numerical solvers, plotting, etc) is provided by `Packages`. Julia uses `environments` defined to a `Project.toml` file to control the loading of `Packages`, which implement `Modules` loaded by `import` or `using` (eg `import DifferentialEquations` to use the DifferentialEquations package).

The environment for using PALEOtutorials.jl is defined by `PALEOtutorials.jl/examples/Project.toml`. This adds PALEOtoolkit packages including `PALEOboxes`, `PALEOmodel` and required dependencies.

To activate this environment:
- In `VS code`, right click on any file in the `PALEOtutorials.jl/examples` folder and select `Julia: activate parent environment` from the pop-up menu.

Then download Julia packages: from the Julia REPL,

    julia> import Pkg
    julia> Pkg.instantiate()  # one-time initialisation for a new installation


## Running the examples

Start the julia REPL inside VS code, navigate to the `PALEOtutorials.jl/examples` folder, and activate the correct Julia environment:
- In `VS code`, right click on any file in the `PALEOtutorials.jl/examples` folder and select `Julia: activate parent environment` from the pop-up menu.

Individual examples can then be run by eg

    julia> cd("CPU")  # PALEOtutorials.jl/examples/CPU
    julia> include("CPU_examples.jl")  # run CPU model example

See the online [Documentation](https://paleotoolkit.github.io/PALEOtutorials.jl/) for details.