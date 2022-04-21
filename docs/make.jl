using Documenter

using DocumenterCitations

bib = CitationBibliography(joinpath(@__DIR__, "src/paleo_references.bib"))

makedocs(bib, sitename="PALEOcopse Documentation", 
# makedocs(sitename="PALEO Documentation", 
    pages = [
        "index.md",
        "Examples and Tutorials" => [
            "ExampleInstallConfig.md",
            "ExampleCPU.md",
        ],
        # no Design docs yet
        "HOWTOS" => [
            "HOWTOJuliaUsage.md",
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
