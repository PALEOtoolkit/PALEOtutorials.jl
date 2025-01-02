

# Displaying model configuration and output from the Julia REPL

The specific examples below were generated after running the [`PALEOcopse`](https://github.com/PALEOtoolkit/PALEOcopse.jl) `COPSE Reloaded` example from the Julia REPL, but apply to any PALEOtoolkit model.

## Displaying large tables in Julia
Several PALEO commands produce large tables.

There are several options to display these:
- Julia in VS code provides the `julia> vscodedisplay(<some table>)` command. As of Jan 2022 this is now usually the best option.
- Use `julia> show(<some table>, allcols=true, allrows=true)` to show as text in the REPL. 
- Use `julia> CSV.write("some_table.csv", <some table>)` to save as a CSV file and open in Excel etc.

## Find code and documentation

The documentation for a PALEO reaction can be looked up using the  `PALEOboxes.doc_reaction` command:

    julia> PB.doc_reaction("ReactionReservoirScalar")

NB: the VS Code Documentation browser has similar functionality and is often easier to use. The key difference that it looks at definitions visible in the VS code projects and editor windows, whilst doc_reaction looks at definitions available to code in the current REPL ie provided by modules that are currently loaded in the REPL.

## Display model configuration

### Display parameters:

Examples illustrating the use of [`PALEOboxes.show_parameters`](@extref):

To show parameters for every Reaction in the model:

    julia> vscodedisplay(PB.show_parameters(model)) # show in VS code table viewer
    julia> show(PB.show_parameters(model), allrows=true) # show as text in REPL 
    julia> import CSV
    julia> CSV.write("parameters.csv", PB.show_parameters(model)) # save as CSV for Excel etc

This illustrates the modularised model structure, with:
- Domains global, atm, land, ocean, oceansurface, oceanfloor, sedcrust containing forcings and biogeochemical Reactions, with Parameters attached to each Reaction.
- Additional Domains fluxAtoLand, fluxLandtoSedCrust, fluxOceanBurial, fluxOceanfloor, fluxRtoOcean, fluxSedCrusttoAOcean containing flux coupler Reactions.

To show parameters for a single Reaction:
    
    julia> rct_temp_global = PB.get_reaction(model, "global", "temp_global")
    julia> PB.show_parameters(rct_temp_global)    # GEOCARB temperature function parameters

The Julia Type of `rct_temp_global` `PALEOcopse.Global.Temperature.ReactionGlobalTemperatureBerner` usually makes it possible to guess the location `src/global/Temperature.jl` in the source code <https://github.com/PALEOtoolkit/PALEOcopse.jl> of the `PALEOcopse` Julia package.

### Display Variables:

#### Show Variables in the model:

Use [`PALEOboxes.show_variables`](@extref) to list all Variables in the model, or Variables for a specific Domain:

    julia> vscodedisplay(PB.show_variables(model)) # VS code only
    julia> vscodedisplay(PB.show_variables(model, "land")) # just the "land" Domain

To list full information for all Variables in the model (including Variable linking and current values):

    julia> vscodedisplay(PB.show_variables(model; modeldata=modeldata, showlinks=true))

This illustrates the modularized model structure, with:

- Domains global, atm, land, ocean, oceansurface, oceanfloor, sedcrust containing Variables linked to Reactions (either property-dependencies or target-contributors pairs).
- Additional Domains fluxAtoLand, fluxLandtoSedCrust, fluxOceanBurial, fluxOceanfloor, fluxRtoOcean, fluxSedCrusttoAOcean containing target-contributor pairs representing inter-module fluxes.

#### Show linkage for a single Domain or ReactionMethod Variable

To show linkage of a single Variable in Domain "atm" with name "pO2PAL":

    julia> PB.show_links(model, "atm.pO2PAL")

To show linkage of a ReactionMethod Variable with localname "pO2PAL", Reaction "ocean_copse" in Domain "ocean":

    julia> PB.show_links(PB.get_reaction_variables(model, "ocean", "ocean_copse", "pO2PAL"))

## Display model output

Model output is stored in a [`PALEOmodel.AbstractOutputWriter`](@extref) object, which is
available as `paleorun.output`, ie the `output` field of the default [`PALEOmodel.Run`](@extref) instance created
by the `COPSE_reloaded_reloaded.jl` script.

The default [`PALEOmodel.OutputWriters.OutputMemory`](@extref) stores model output in memory, by Domain:

    julia> paleorun.output  # shows Domains

To show metadata for all Variables in the output:

    julia> vscodedisplay(PB.show_variables(paleorun.output)) # VS code only
    julia> vscodedisplay(PB.show_variables(paleorun.output, "land")) # just the land Domain

Output from a list of Variables or for each `Domain` can be exported to a Julia [DataFrame](https://dataframes.juliadata.org/stable/):

    julia> # display data for a list of Variables as a Table
    julia> vscodedisplay(PB.get_table(paleorun.output, ["atm.tmodel", "atm.pCO2PAL", "fluxOceanBurial.flux_total_P"]))

    julia> # display data for every Variable in the 'atm' Domain as a Table
    julia> vscodedisplay(PB.get_table(paleorun.output, "atm"))

    julia> # show a subset of output variables from the 'atm' Domain
    julia> PB.get_table(paleorun.output, "atm")[!, [:tmodel, :pCO2atm, :pCO2PAL]]

Data from each Variable can be accessed as a [`PALEOmodel.FieldArray`](@extref) (a Python-xarray like struct with
named dimensions and coordinates):

    julia> pCO2atm = PALEOmodel.get_array(paleorun.output, "atm.pCO2atm")
    julia> pCO2atm.values # raw data Array
    julia> pCO2atm.dims_coords # pCO2 is a scalar Variable with one dimension `tmodel` which has one coordinate variable also called `tmodel`
    julia> pCO2atm.dims_coords[1] # first dimension, as a Pair dimension => vector of attached coordinates
    julia> pCO2atm.dims_coords[1][2][1] # coordinate variable (also a FieldArray)
    julia> pCO2atm.dims_coords[1][2][1].values # raw values for model time (`tmodel`) from coordinate variable

Raw data arrays can also be accessed as Julia Vectors using `get_data`:

    julia> pCO2atm_raw = PB.get_data(paleorun.output, "atm.pCO2atm")  # raw data Array
    julia> tmodel_raw = PB.get_data(paleorun.output, "atm.tmodel") # raw data Array

(here these are the values and coordinate of the `pCO2atm` [`PALEOmodel.FieldArray`](@extref), ie `pCO2atm_raw == pCO2atm.values` and `tmodel_raw == pCO2atm.dims_coords[1][2][1].values`).

## Plot model output

The output can be plotted using the Julia Plots.jl package, see [Plotting output](@extref PALEOmodel). Plot recipes are defined for [`PALEOmodel.FieldArray`](@extref), so output data can be plotted directly using the `plot` command:

    julia> using Plots

    julia> plot(paleorun.output, "atm.pCO2atm")  # plot output variable as a single command
    julia> plot(title="Oxygen", paleorun.output, ["atm.pO2PAL", "ocean.ANOX"]) # overlay multiple output variables in one plot

    julia> pCO2atm = PALEOmodel.get_array(paleorun.output, "atm.pCO2atm")
    julia> plot(pCO2atm) # a PALEOmodel.FieldArray can be plotted

    julia> pCO2atm_raw = PB.get_data(paleorun.output, "atm.pCO2atm")  # raw data Array
    julia> tmodel_raw = PB.get_data(paleorun.output, "atm.tmodel") # raw data Array
    julia> plot!(tmodel_raw, pCO2atm_raw, label="some raw data") # overlay data from standard Julia Vectors

## Spatial or wavelength-dependent output

To analyze spatial or eg wavelength-dependent output (eg time series from a 1D column or 3D general circulation model, or quantities that are a function of wavelength or frequency), `PALEOmodel.get_array` takes an additional `selectargs::NamedTuple` argument to take 1D or 2D slices from the spatial, spectral and timeseries data. The [`PALEOmodel.FieldArray`](@extref) returned includes default coordinates to plot column (1D) and heatmap (2D) data, these can be overridden by supplying the optional `coords` keyword argument.

### Examples for a column-based model

Visualisation of spatial and wavelength-dependent output from the PALEOatmosphere.jl ozone photochemistry example (a single 1D atmospheric column):

#### 1D column data
To plot O3 mixing ratio vs height in the 1D atmosphere column, at the last model timestep:

    julia> plot(title="O3 mixing ratio", paleorun.output, "atm.O3_mr", (tmodel=1e12, column=1),
                swap_xy=true, xscale=:log10) # plots O3 vs default height coordinate, at the nearest model time to 1e12 yr (ie the last timestep)

To plot results from multiple output times:

    julia> plot(title="O3 mixing ratio", paleorun.output, "atm.O3_mr", (tmodel=[0.0, 0.1, 1.0, 10.0, 100.0, 1000.0], column=1),
                swap_xy=true, xscale=:log10, labelattribute=:filter_records) # plots O3 vs default height coordinate

Here the plot recipe expands the Vector-valued `tmodel` argument to create a composite plot. The optional `labelattribute=:filter_records` keyword argument is used to generate plot labels from the `:filter_records` FieldArray attribute, which contains the `tmodel` values used to select the timeseries records.  

This is equivalent to first creating and then plotting a sequence of `FieldArray` objects:

    julia> O3_mr = PALEOmodel.get_array(paleorun.output, "atm.O3_mr", (tmodel=0.0, column=1))
    julia> plot(title="O3 mixing ratio", O3_mr, swap_xy=true, xscale=:log10, labelattribute=:filter_records)
    julia> O3_mr = PALEOmodel.get_array(paleorun.output, "atm.O3_mr", (tmodel=0.1, column=1))
    julia> plot!(O3_mr, swap_xy=true, labelattribute=:filter_records)

The default height coordinate from the model grid can be replaced using the optional `coords` keyword argument, eg

    julia> plot(title="O3 mixing ratio", paleorun.output, "atm.O3_mr", (tmodel=[0.0, 0.1, 1.0, 10.0, 100.0, 1000.0], column=1),
                coords=["cells"=>("atm.pmid", "atm.plower", "atm.pupper")],
                swap_xy=true, xscale=:log10, yflip=true, yscale=:log10, labelattribute=:filter_records) # plots O3 vs pressure

#### Wavelength-dependent data
    julia> plot(title="direct transmittance", paleorun.output, ["atm.direct_trans"], (tmodel=1e12, column=1, cell=[1, 80]),
                ylabel="fraction", labelattribute=:filter_region) # plots vs wavelength

Here `tmodel=1e12` selects the nearest model time to 1e12 yr ie the last model time output, and `column=1, cell=[1, 80]` selects the top and bottom cells within the first (only) 1D column. The `labelattribute=:filter_region` keyword argument is used to generate plot labels from the `:filter_region` FieldArray attribute, which contains the `column` and `cell` values used to select the spatial region.

### Examples for a 3D GCM-based model

Visualisation of spatial output from the 3D MITgcm transport-matrix example (PALEOocean.jl repository)

### Horizontal slices across levels
    julia> heatmap(paleorun.output, "ocean.O2_conc", (tmodel=1e12, zt_isel=1, expand_cartesian=true), swap_xy=true)

Here `zt_isel=1` selects a horizontal level corresponding to model grid cells with index of 'zt' dimension = 1, which is the ocean surface in the MITgcm grid (NB: naming of dimensions is specific to model configurations, as is ordering and sign of depth coordinates hence need for `swap_xy` option). `expand_cartesian=true` expands the internal storage from a vector of cells to a 3D cartesian grid.

### Vertical section at constant longitude
    julia> heatmap(paleorun.output, "ocean.O2_conc", (tmodel=1e12, lon=340.0, expand_cartesian=true), swap_xy=true)

Here `lon=340.0` selects a section at the nearest 'lon' coordinate to 340.0 degrees east (NB: naming of dimensions is specific to model configurations, as is ordering and sign of depth coordinates hence need for `swap_xy` and `mult_y_coord` options).

### Exporting to netcdf to use xarray etc

PALEO output (see below) is in standard netcdf format with the ocean data in the ocean group of a multi-group netcdf file, so can be analyzed using eg the Python `xarray` package, see example Jupyter notebook in the `PALEOocean` repository, `examples/mitgcm` folder. 

## Save and load output

Model output can be saved and loaded using the [`PALEOmodel.OutputWriters.save_netcdf`](@extref) and [`PALEOmodel.OutputWriters.load_netcdf!`](@extref) methods.

Output attempts to follow standard netcdf conventions. NB each PALEO Domain is a separate group in a multi-group netcdf file.

## Export output to a CSV file

To write Model output from a single Domain to a CSV file:

    julia> import CSV
    julia> CSV.write("copse_land.csv", PB.get_table(paleorun.output, "land")) # all Variables from land Domain
    julia> CSV.write("copse_atm.csv", PB.get_table(paleorun.output, "atm")[!, [:tmodel, :pCO2atm, :pO2atm]]) # subset of Variables from atm Domain
