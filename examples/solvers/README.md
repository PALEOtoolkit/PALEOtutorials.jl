# ODE solvers

These examples use of different ODE solvers for [Example 5 Isotopes and Rayleigh fractionation](@ref)

## Naive first-order explicit Euler 'by hand'

This example demonstrates a naive approach using first-order explicit Euler to integrate the two state variables `Box1.A` and `Box2.B` forward in time,
using a fixed timestep of 0.5 yr.  This can be useful for testing, but for convenience and accuracy for practical use, it is usually better to use the PALEOmodel wrappers for the Julia SciML solvers, see <https://paleotoolkit.github.io/PALEOmodel.jl/stable/PALEOmodelSolvers/>.

!!! warning
    This is NOT recommended except for testing - use the [PALEOmodel wrappers](https://paleotoolkit.github.io/PALEOmodel.jl/stable/PALEOmodelSolvers/) for the solvers from the Julia SciML ecosystem, as described below.

The script to run the model (file `examples/reservoirs/run_ex5.yaml`) contains:
```@eval
str = read("../../../../examples/solvers/run_ex5_naive_euler.jl", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```
And produces output (solid lines, dashed lines show accurate output from CVODE solver):
```@setup solvers
include("../../../../examples/reservoirs/run_ex5.jl")
output_cvode = paleorun.output
include("../../../../examples/solvers/run_ex5_naive_euler.jl")
```
```@example solvers
plot(output_euler,  ["Box1.A", "Box2.B", "global.E_total"]; ylabel="reservoir (mol)") # hide
plot!(output_cvode,  ["Box1.A", "Box2.B", "global.E_total"]; ylabel="reservoir (mol)", linestyle=:dash) # hide
savefig("ex5_naive_euler_plot1.svg")  # hide
plot(output_euler, ["Box1.decay_flux", "fluxBoxes.flux_B"]; ylabel="flux (mol yr-1)")  # hide
plot!(output_cvode, ["Box1.decay_flux", "fluxBoxes.flux_B"]; ylabel="flux (mol yr-1)", linestyle=:dash)  # hide
savefig("ex5_naive_euler_plot2.svg"); nothing # hide
plot(output_euler, ["Box1.A_delta", "Box1.decay_flux.v_delta", "Box2.B_delta", "global.E_total.v_delta", ]; ylabel="delta (per mil)") # hide
plot!(output_cvode, ["Box1.A_delta", "Box1.decay_flux.v_delta", "Box2.B_delta", "global.E_total.v_delta", ]; ylabel="delta (per mil)", linestyle=:dash) # hide
savefig("ex5_naive_euler_plot3.svg"); nothing # hide
```

![](ex5_naive_euler_plot1.svg)
![](ex5_naive_euler_plot2.svg)
![](ex5_naive_euler_plot3.svg)

Note that although isotope mass balance is maintained, and the final state for B is correct, the Rayleigh fractionation of A is inaccurate due to the coarse timestep and inaccuracy of the first-order explicit Euler method.

## PALEOmodel default SUNDIALS CVODE solver

This repeats [Example 5 Isotopes and Rayleigh fractionation](@ref), which uses the `PALEOmodel.ODE.integrate` wrapper function for the solvers in the
Julia [SciML](https://diffeq.sciml.ai/stable/) ecosystem. The PALEOmodel default solver (set by the `alg` argument) is [SUNDIALS CVODE](https://diffeq.sciml.ai/stable/solvers/ode_solve/#ode_solve_sundials). This is a stiff solver that requires a Jacobian, either (as here) calculated using finite differences or passed explicitly, where [PALEOmodel](https://paleotoolkit.github.io/PALEOmodel.jl/stable/PALEOmodelSolvers/#High-level-wrappers) includes options to calculate a sparse Jacobian using automatic differentiation.

Options `solvekwargs` are passed through to the SciML `solve` method, see <https://diffeq.sciml.ai/dev/basics/common_solver_opts/>.

The script to run the model (file `examples/reservoirs/run_ex5.jl`) contains:
```@eval
str = read("../../../../examples/reservoirs/run_ex5.jl", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```
and produces output showing Rayleigh fractionation:
```@example solvers
plot(output_cvode,  ["Box1.A", "Box2.B", "global.E_total"]; ylabel="reservoir (mol)") # hide
savefig("ex5_plot1.svg")  # hide
plot(output_cvode, ["Box1.decay_flux", "fluxBoxes.flux_B"]; ylabel="flux (mol yr-1)")  # hide
savefig("ex5_plot2.svg"); nothing # hide
plot(output_cvode, ["Box1.A_delta", "Box1.decay_flux.v_delta", "Box2.B_delta", "global.E_total.v_delta", ]; ylabel="delta (per mil)") # hide
savefig("ex5_plot3.svg"); nothing # hide
```

![](ex5_plot1.svg)
![](ex5_plot2.svg)
![](ex5_plot3.svg)

## Using a non-default solver

Recommended SciML solvers are documented at <https://diffeq.sciml.ai/stable/>. As this system is not stiff (no short timescales) the SciML Tsit5 solver is also a good choice, set using the `alg` argument to `PALEOmodel.ODE.integrate` (this is passed through to the SciML `solve` method).

The script to run the model (file `examples/reservoirs/run_ex5.yaml`) with this solver contains:
```@eval
str = read("../../../../examples/solvers/run_ex5_Tsit5.jl", String)
str = """```julia
      $str
      ```"""
import Markdown
Markdown.parse(str)
```
As expected the output using Tsit5 (solid lines) and CVODE_BDF (dashed lines) is indistinguishable as both solvers will maintain relative accuracy within the specified `reltol=1e-5`:
```@setup solvers
include("../../../../examples/solvers/run_ex5_Tsit5.jl")
output_tsit5 = paleorun.output
```
```@example solvers
plot(output_tsit5,  ["Box1.A", "Box2.B", "global.E_total"]; ylabel="reservoir (mol)") # hide
plot!(output_cvode,  ["Box1.A", "Box2.B", "global.E_total"]; ylabel="reservoir (mol)", linestyle=:dash) # hide
savefig("ex5_tsit5_plot1.svg")  # hide
plot(output_tsit5, ["Box1.decay_flux", "fluxBoxes.flux_B"]; ylabel="flux (mol yr-1)")  # hide
plot!(output_cvode, ["Box1.decay_flux", "fluxBoxes.flux_B"]; ylabel="flux (mol yr-1)", linestyle=:dash)  # hide
savefig("ex5_tsit5_plot2.svg"); nothing # hide
plot(output_tsit5, ["Box1.A_delta", "Box1.decay_flux.v_delta", "Box2.B_delta", "global.E_total.v_delta", ]; ylabel="delta (per mil)") # hide
plot!(output_cvode, ["Box1.A_delta", "Box1.decay_flux.v_delta", "Box2.B_delta", "global.E_total.v_delta", ]; ylabel="delta (per mil)", linestyle=:dash) # hide
savefig("ex5_tsit5_plot3.svg"); nothing # hide
```

![](ex5_tsit5_plot1.svg)
![](ex5_tsit5_plot2.svg)
![](ex5_tsit5_plot3.svg)
