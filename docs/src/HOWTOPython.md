# Configuring for Julia - python interoperability

Julia has near-seamless interoperability with Python, provided by the [PyCall.jl](https://github.com/JuliaPy/PyCall.jl) and [Conda.jl](https://github.com/JuliaPy/Conda.jl) packages in the [JuliaPy](https://github.com/JuliaPy) github organisation.

However configuration of Python and Julia inevitably introduces dependencies.  There are two overall strategies:
1. allow Julia to install and maintain a private Python installion (the default)
2. configure Julia and Python for a shared Python installation

## 1. Private Python installation for Julia
This is simplest for cases where you just want to use a few python packages from Julia (eg IJulia for Jupyter notebooks).

    julia> ENV["PYTHON"]="" 
    julia> Pkg.add("PyCall")  # will build automatically

Rebuild PyCall after installation to use private python installation:

    julia> ENV["PYTHON"]="" 
    julia> Pkg.build("PyCall")  # will rebuild to use private Python install, and install Matplotlib next time PyPlot is imported.

(Re)build Julia packages that depend on python:

    julia> ENV["JUPYTER"]="";
    julia> Pkg.build("IJulia")  # force IJulia to use its own Conda-based Jupyter version


## 2. Use an external python installation
As of 2021-12-06, the simplest way to do this is to use [miniforge](https://github.com/conda-forge/miniforge) to manage the python installation.

(Re)build [Conda.jl](https://github.com/JuliaPy/Conda.jl) to use the pre-existing Conda installation: 

    julia> ENV["CONDA_JL_HOME"] = "/home/sd336/miniforge3/envs/conda_jl38"  # path from unix> conda info --envs
    pkg> build Conda

(Re)build [PyCall.jl](https://github.com/JuliaPy/PyCall.jl)

    julia> ENV["PYTHON"] = "/home/sd336/miniforge3/envs/conda_jl38/bin/python"  # may be redundant (picks up location from Conda.jl ?)
    pkg> build PyCall

Restart Julia

    julia> PyCall.libpython  # check we have picked up the new libpython etc
    "/home/sd336/miniforge3/envs/conda_jl38/lib/libpython3.8.so.1.0"

(Re)build [IJulia.jl](https://github.com/JuliaLang/IJulia.jl):

    julia> ENV["JUPYTER"] = "/home/sd336/miniforge3/envs/conda_jl38/bin/jupyter" # path from unix> which jupyter
    "/home/sd336/miniforge3/envs/conda_jl38/bin/jupyter"

    pkg> build IJulia
