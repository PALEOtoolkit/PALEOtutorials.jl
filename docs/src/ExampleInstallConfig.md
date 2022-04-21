# Installation and initial configuration

## Installing and configuring Julia

Download and install Julia from <https://julialang.org/downloads/>

## Install VS Code
Install VS Code from <https://code.visualstudio.com/download>
Follow instructions at <https://github.com/julia-vscode/julia-vscode> to install the Julia extension.

## Clone github repository
This will download <https://github.com/sjdaines/PALEOdev.jl> into a new folder `PALEOjulia`

    git clone https://github.com/sjdaines/PALEOdev.jl PALEOjulia


## Configure PALEO environment, build documentation, run tests

Launch VScode from the `PALEOjulia` folder, or use Menu->File->Open folder from inside VSCode to change to this folder.

Start Julia REPL: VScode menu View -> Command Palette, search for Julia, select `Julia: Start REPL` 

Run the `PALEO_setup.jl` setup script to add package dependencies between the PALEO packages (this is a one-time configuration, 
necessary as the PALEO packages are not yet registered with the Julia ecosystem), build documentation, and run tests
(this takes ~45min on my newish laptop from a new Julia install):
    
    julia> pwd()    # check we are in the top-level PALEO.jl folder
    "E:\\software\\julia\\PALEOjulia"   

    julia> include("PALEO_setup.jl")

## View documentation

Documentation is available as local web pages at `PALEOjulia\docs\build\index.html` (this is a temporary solution until
the PALEO repository is made public, at which point these will become publically viewable web pages hosted by github).

This html documentation is built from files in `PALEOjulia\docs\src` by the script `PALEOjulia\docs\make.jl` (included in `PALEO_setup.jl`)

## Packages, projects and environments
The majority of high-level Julia functionality (numerical solvers, plotting, etc) is provided by `Packages`. Julia uses `environments` defined to a `Project.toml` file to control the loading of `Packages`, which implement `Modules` loaded by `import` or `using` (eg `import DifferentialEquations` to use the DifferentialEquations package). `Packages` can be registered with the Julia repository to make them generally available for download.

The recommended environment for using PALEO.jl is defined by `PALEOjulia\PALEOexamples\Project.toml`.

This environment adds the `PALEOboxes`, `PALEOreactions` and `PALEOmodel` packages (using `develop`, as these are local packages not yet registered with the Julia ecosystem).

In `VS code`, right click on the file browser to change directory and `activate` environments (`activate parent environment`).

From the Julia REPL (command line), `activate` an environment using the package manager (called `Pkg`, <https://julialang.github.io/Pkg.jl/v1.1/getting-started/>):

    julia> cd("PALEOexamples")
    julia> ]              # magic character to switch to the package manager
    (@1.5>) pkg>         # prompt changes to show we are using the default Julia 1.5 environment
    (@1.5>) pkg> activate .   # activate the PALEOexamples environment defined by Project.toml
    (PALEOexamples) pkg>  # prompt changes to show we are using this environment
    julia>                # hit <BACKSPACE> to return to the command prompt


## Updating Julia packages

Julia `Packages` are frequently (every few days) updated independently of the Julia language itself. The Julia package manager `update` command updates all packages in the currently active Julia `environment`.
The `PALEO_updatepkg.jl` script provides a convenience wrapper to update each of the PALEO environments
(`PALEOboxes, PALEOreactions, PALEOmodel, PALEOexamples, docs, cfortranapi`):

    julia> pwd()    # check we are in the top-level PALEO.jl folder
    "E:\\software\\julia\\PALEOjulia"   

    julia> include("PALEO_updatepkg.jl") # update all 6 PALEO environments

## Optional additional configuration: Jupyter notebooks

The Julia language (like Python and R, unlike Matlab) can use multiple different development workflows, including the Jupyter environment and notebooks via the `IJulia` package (this is the 'Ju' in Jupyter <https://blog.jupyter.org/i-python-you-r-we-julia-baf064ca1fb6>).

Using Jupyter notebooks does however introduce a dependency on Python. The most reliable way to get this working is to ask IJulia to install its own Conda-based version of Python and Jupyter (see <https://julialang.github.io/IJulia.jl/stable/>):

    julia> using Pkg   # the Julia package manager
    julia> pwd()    # check we are in the top-level PALEO.jl folder
    "E:\\software\\julia\\PALEOjulia"       
    julia> Pkg.activate("PALEOexamples")  # activate the PALEOexamples environment
    julia> ENV["JUPYTER"]=""; Pkg.build("IJulia")  # force IJulia to use its own Conda-based Jupyter version
    julia> using IJulia  
    julia> notebook(dir=pwd(), detached=true)  # Prompt to install Jupyter, launch an IJulia notebook in your browser

See [Configuring for Julia - python interoperability](@ref) for setup details including how to use an external Python installation.

## Optional additional configuration: Plotting
Julia has multiple plot backends, and these can either use a standalone window or display "inline" to the VS code plot panel (or Jupyter notebook).

### VS code plot panel
Enable/disable the VS code plot panel with the `Julia: Use plot panel` checkbox in VS code settings (search for Julia). If disabled, plotting will use a standalone window.

### GR backend
#### VS code
Enlarging VS plot window using default GR backend: `julia> using Plots; gr(size = (750, 565))`
#### Standalone
The standalone GR plot window (if not using VS code plot panel) can only display one plot in one window, so not recommended.

### PlotlyJS backend
#### VS code
Using PlotlyJS backend in VS code: julia> using Plots; plotlyjs(size=(750, 565)). 
#### Standalone
See <https://github.com/JuliaPlots/PlotlyJS.jl> for note on Blink install.

### Pyplot backend
This requires the Python Matplotlib library, see <https://github.com/JuliaPy/PyPlot.jl> for installation instructions. The simplest configuration is for Julia to install a private (not system provided) Python distribution.  On linux, this requires that you set ENV["PYTHON"]="" before adding PyPlot:

    julia> ENV["PYTHON"]="" 
    julia> Pkg.add("PyPlot")  # will automatically install python Matplotlib etc as needed and the Qt backend
or if PyPlot is already installed but failing with a system Python,

    julia> ENV["PYTHON"]="" 
    julia> Pkg.build("PyCall")  # will rebuild to use private Python install, and install Matplotlib next time PyPlot is imported.

See [Configuring for Julia - python interoperability](@ref) for setup details including how to use an external Python installation.

#### VS code
Using pyplot backend in VS code: julia> using Plots; pyplot()
#### Standalone
On linux, install process above will use the Qt backend by default, see <https://github.com/JuliaPy/PyPlot.jl> for instructions for MacOS.

## Optional additional configuration: SIMD vectorized math functions
By default, Julia (as of version 1.6) will fall back to slow scalar functions for SIMD exp, log etc, which has a big (x2) impact on the speed of carbonate chemistry and hence run time for large (GENIE size) models that use many small fixed timesteps. As a workaround, PALEO will use the sleef library (<https://sleef.org>) for fast vectorized versions, supplied by the SLEEF_jll.jl package.

## Optional additional configuration: local paths in LocalPreferences.toml
PALEO uses Julia [Preferences.jl](https://github.com/JuliaPackaging/Preferences.jl) to simplify configuration
for data files that are not part of the PALEO repo hence may be in a different location on the local machine.

Any Parameter value string in \$ \$ eg `$SomePath$` will be substituted with the value of the key `SomePath` read from the `LocalPreferences.toml` file in the top-level folder for the current environment (eg `PALEOexamples/LocalPreferences.toml`).

Currently this mechanism is used to define paths for external data files for ocean transport, via the keys
`S2P3TransportDir`, `GENIETransportDir`, `TMMDir`.
