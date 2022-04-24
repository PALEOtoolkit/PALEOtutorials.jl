# Installation and initial configuration

## Installing and configuring Julia and VS Code

### Julia
Download and install Julia from <https://julialang.org/downloads/> (PALEO requires Julia 1.6 or a later version).

### VS Code
Install VS Code from <https://code.visualstudio.com/download>
Follow instructions at <https://github.com/julia-vscode/julia-vscode> to install the Julia extension.

## Installing and configuring the PALEOtutorials

### Clone github repository
This will download <https://github.com/sjdaines/PALEOtutorials.jl> into a new folder `PALEOtutorials`

    git clone https://github.com/PALEOtoolkit/PALEOtutorials.jl PALEOtutorials


### Start a Julia REPL in VS code

Launch VScode from the `PALEOtutorials` folder, or use Menu->File->Open folder from inside VSCode to change to this folder.

Start Julia REPL: VScode menu View -> Command Palette, search for Julia, select `Julia: Start REPL` 

### Activate the Julia environment and install packages

The majority of high-level Julia functionality (numerical solvers, plotting, etc) is provided by `Packages`. Julia uses `environments` defined to a `Project.toml` file to control the loading of `Packages`, which implement `Modules` loaded by `import` or `using` (eg `import DifferentialEquations` to use the DifferentialEquations package). `Packages` can be registered with the Julia repository to make them generally available for download.

The recommended environment for using PALEOtutorials.jl is defined by `PALEOtutorials\examples\Project.toml`. This adds the `PALEOboxes`, `PALEOmodel` and `PALEOcopse` packages.

To activate the correct Julia environment, either:
- In `VS code`, right click on a file in the `PALEOtutorials\examples` folder and `activate parent environment`.

- Or from the Julia REPL (command line), use the package manager (called `Pkg`, <https://julialang.github.io/Pkg.jl/v1.1/getting-started/>):

        julia> cd("PALEOtutorials/examples")
        julia> import Pkg
        julia> Pkg.activate(".")

Then download packages, from the Julia REPL:

    julia> Pkg.instantiate()  # one-time initialisation for a new installation

