using Documenter

using DocumenterCitations

import PALEOboxes as PB

bib = CitationBibliography(joinpath(@__DIR__, "src/paleo_references.bib"))

# Collate all markdown files and images folders from PALEOexamples/src/ into a tree of pages
io = IOBuffer()
println(io, "Collating all markdown files from ./examples:")
examples_folder = "collated_examples"  
examples_path = normpath(@__DIR__, "src", examples_folder)  # temporary folder to collate files
rm(examples_path, force=true, recursive=true)
examples_pages, examples_includes = PB.collate_markdown(
    io, normpath(@__DIR__, "../examples"), @__DIR__, examples_folder;
)
@info String(take!(io))

# include files that load modules etc from PALEOexamples folders
include.(examples_includes)

makedocs(bib, sitename="PALEOtutorials Documentation", 
# makedocs(sitename="PALEO Documentation", 
    pages = [
        "index.md",
        "Examples and Tutorials" => vcat(
            "ExampleInstallConfig.md",
            examples_pages,
        ),
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

rm(examples_path, force=true, recursive=true)

deploydocs(
    repo = "github.com/PALEOtoolkit/PALEOtutorials.jl.git",
)
