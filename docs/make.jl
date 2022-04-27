using Documenter

using DocumenterCitations

bib = CitationBibliography(joinpath(@__DIR__, "src/paleo_references.bib"))

# Workaround for problem with @example block:
# include that defines new AbstractReaction subtype is apparently invisible
# to InteractiveUtils.subtypes()
include("../examples/reservoirs/reactions_ex1.jl")
include("../examples/reservoirs/reactions_ex2.jl")
include("../examples/reservoirs/reactions_ex3.jl")
include("../examples/reservoirs/reactions_ex5.jl")

makedocs(bib, sitename="PALEOtutorials Documentation", 
# makedocs(sitename="PALEO Documentation", 
    pages = [
        "index.md",
        "Examples and Tutorials" => [
            "ExampleInstallConfig.md",
            "ExampleReservoirs.md",
            "ExampleCPU.md",
        ],
        # no Design docs yet
        "HOWTOS" => [
            "HOWTOJuliaUsage.md",
            "HOWTOadditionalconfig.md",
            "HOWTOminimalGit.md",
            "HOWTOPython.md",
        ],
        # no Reference doc yet
        "References.md",
        "indexpage.md",
    ],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
)

@info "Local html documentation is available at $(joinpath(@__DIR__, "build/index.html"))"

deploydocs(
    repo = "github.com/PALEOtoolkit/PALEOtutorials.jl.git",
)
