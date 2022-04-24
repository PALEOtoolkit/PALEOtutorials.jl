# Optional additional configuration

## Local paths in LocalPreferences.toml

PALEO uses Julia [Preferences.jl](https://github.com/JuliaPackaging/Preferences.jl) to simplify configuration
for data files that are not part of the PALEO repo hence may be in a different location on the local machine.

Any Parameter value string in \$ \$ eg `$SomePath$` will be substituted with the value of the key `SomePath` read from the `LocalPreferences.toml` file in the top-level folder for the current environment (eg `PALEOexamples/LocalPreferences.toml`).

Currently this mechanism is used to define paths for external data files for ocean transport, via the keys
`S2P3TransportDir`, `GENIETransportDir`, `TMMDir`.

## Jupyter notebooks

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

## Plotting
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

## SIMD vectorized math functions
By default, Julia (as of version 1.6) will fall back to slow scalar functions for SIMD exp, log etc, which has a big (x2) impact on the speed of carbonate chemistry and hence run time for large (GENIE size) models that use many small fixed timesteps. As a workaround, PALEO will use the sleef library (<https://sleef.org>) for fast vectorized versions, supplied by the SLEEF\_jll.jl package.  This can be disabled by setting `USE_SLEEF = false` in LocalPreferences.toml and restarting the Julia REPL.

