# Julia usage

## Julia resources
- Julia manual <https://docs.julialang.org/en/v1>
- Think Julia book (an introduction to programming) <https://benlauwens.github.io/ThinkJulia.jl/latest/book.html>
- Julia cheatsheet: <https://juliadocs.github.io/Julia-Cheat-Sheet>
- Matlab-Python-Julia cheatsheet: <https://cheatsheets.quantecon.org> (NB: the first example on Creating Vectors is misleading - use 1d Arrays in Julia!)

## Always use Revise.jl
This tracks changes and automatically updates code run from a REPL session.

    julia> using Revise

VS code has an option to automatically load Revise.jl at startup (enabled by default).

## Use Infiltrator.jl for debugging
<https://github.com/JuliaDebug/Infiltrator.jl>

The Debugger.jl built in to VSCode is an interpreter (Interpreter.jl), and is unusably slow for PALEO.

## Julia best practices
- Performance tips: <https://docs.julialang.org/en/v1/manual/performance-tips/>
- Julia antipatterns: <https://www.oxinabox.net/2020/04/19/Julia-Antipatterns.html>
- Batch usage: <https://github.com/CliMA/ClimateMachine.jl/wiki/Caltech-Central-Cluster>

## Julia bugs/gotchas
- [YAML.jl](https://github.com/JuliaData/YAML.jl) parser allows duplicate keys (later key overwrites earlier) TODO report. This is easy to hit when generating model configurations. Workaround: check the .yaml file using an online validator eg <http://www.yamllint.com/>.
- Continuation lines in multi-line formulas can silently fail (this is easy to hit when copying across Fortran code). Workaround - add brackets.
- Debug in VSCode is very slow. Use [Infiltrator.jl](https://github.com/JuliaDebug/Infiltrator.jl) instead.
- Legends on subplots are merged with some backends eg plotlyjs (<https://github.com/JuliaPlots/Plots.jl/issues/673>). Workaround - use a different backend for multiple-panel plots.
- [jldoctest](https://juliadocs.github.io/Documenter.jl/stable/man/doctests/) fails if there is an initial blank line (apparent off-by-one in input and validation output). TODO report.

## Julia performance issues/gotchas
NB: the only place this matters in PALEO is for the model main loop.  Everything else is non-performance critical.
- It is easy to write code which is 'type unstable', or generates memory allocations, which then gives low performance, see 'Performance tips' above.
- Iterating over tuples: really need a `foreach` that is optimised eg <https://github.com/JuliaLang/julia/issues/31869>, <https://discourse.julialang.org/t/manually-unroll-operations-with-objects-of-tuple/11604>. PALEO provides `PALEOboxes.foreach_longtuple`.
- @views for sparse matrices reverts to slow (dense) pathways (<https://stackoverflow.com/questions/58699267/julia-view-of-sparse-matrix>, <https://github.com/JuliaLang/julia/issues/21796>) (update - much improved in Julia 1.6 according to updates to these posts)
- [SIMD.jl](https://github.com/eschnett/SIMD.jl) is missing optimized vectorized intrinsics (exp, log etc). PALEO provides workaround ins `PALEOboxes.SIMDutils.jl`, implemented using SLEEF.





