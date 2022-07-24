# Configuration Errors

These examples illustrate common configuration errors, for various misconfigurations of [Example 5 Isotopes and Rayleigh fractionation](@ref)

## Syntax error in .yaml config file

The model configuration (file `examples/error_examples/config_ex5_syntax_error.yaml`) contains a syntax error in the .yaml config file,
hence the initial parsing of the file fails.
```@eval
str = read("../../../../examples/error_examples/config_ex5_syntax_error.yaml", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

This results in an error when the file is parsed (note that the informative message indicating that there is a problem with the YAML parsing is near the top of the stack trace):
```@repl
try # hide
      include("../../../../examples/error_examples/run_ex5_syntax_error.jl")
catch # hide
      rethrow() # hide
end # hide
```

## Missing / unlinked Variables

The model configuration (file `examples/error_examples/config_ex5_reservoir_A_missing.yaml`) omits a `ReactionReservoirScalar`,
resulting in Variable Dependencies and Contributors with no corresponding Properties and Targets.
```@eval
str = read("../../../../examples/error_examples/config_ex5_reservoir_A_missing.yaml", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

This results in an error when the Variables are linked:
```@repl
try # hide
      include("../../../../examples/error_examples/run_ex5_reservoir_A_missing.jl")
catch # hide
      rethrow() # hide
end # hide
```

## A duplicated Variable or a name collision

The model configuration (file `examples/error_examples/config_ex5_reservoir_A_duplicate.yaml`) contains two copies of a
`ReactionReservoirScalar`, both attempting to create the same VariableDomains
```@eval
str = read("../../../../examples/error_examples/config_ex5_reservoir_A_duplicate.yaml", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

This results in an error when the Variables are linked:
```@repl
try # hide
      include("../../../../examples/error_examples/run_ex5_reservoir_A_duplicate.jl")
catch # hide
      rethrow() # hide
end # hide
```

## Mismatch in :field_data Type (eg isotopes) (Reservoir)

The model configuration (file `examples/error_examples/config_ex5_reservoir_A_noisotope.yaml`) 
contains one `ReactionReservoirScalar` with `:field_data=ScalarData` where this species should have 
`:field_data=IsotopeLinear`:
```@eval
str = read("../../../../examples/error_examples/config_ex5_reservoir_A_noisotope.yaml", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

This results in an error when the Variables are linked:
```@repl
try # hide
      include("../../../../examples/error_examples/run_ex5_reservoir_A_noisotope.jl")
catch # hide
      rethrow() # hide
end # hide
```

## Mismatch in :field_data Type (eg isotopes) (Flux)

The model configuration (file `examples/error_examples/config_ex5_flux_noisotope.yaml`) 
contains a Variable defined by a `ReactionFluxTarget` with default `:field_data=ScalarData` where this species should have 
`:field_data=IsotopeLinear`:
```@eval
str = read("../../../../examples/error_examples/config_ex5_flux_noisotope.yaml", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```

This results in an error when the Variables are linked:
```@repl
try # hide
      include("../../../../examples/error_examples/run_ex5_flux_noisotope.jl")
catch # hide
      rethrow() # hide
end # hide
```

