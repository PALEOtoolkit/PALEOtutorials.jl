using Documenter

using DocumenterCitations

import PALEOboxes as PB

bib = CitationBibliography(
    joinpath(@__DIR__, "src/paleo_references.bib");
    citationstyle=:authoryear,
)

# Collate all markdown files and images folders from PALEOexamples/src/ into a tree of pages
ENV["PALEO_EXAMPLES"] = normpath(@__DIR__, "../examples") # make ENV["PALEO_EXAMPLES"] available in README.md etc
io = IOBuffer()
println(io, "Collating all markdown files from $(ENV["PALEO_EXAMPLES"]):")
examples_folder = "collated_examples"  
examples_path = normpath(@__DIR__, "src", examples_folder)  # temporary folder to collate files
rm(examples_path, force=true, recursive=true)
examples_pages, examples_includes = PB.collate_markdown(
    io, ENV["PALEO_EXAMPLES"], @__DIR__, examples_folder;
)
@info String(take!(io))

# include files that load modules etc from PALEOexamples folders
include.(examples_includes)

makedocs(;
    sitename = "PALEOtutorials Documentation",
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
            "HOWTOdocumentation.md",
            "HOWTOPython.md",
        ],
        # no Reference doc yet
        "References.md",
        "indexpage.md",
    ],
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    plugins = [bib],
)

@info "Local html documentation is available at $(joinpath(@__DIR__, "build/index.html"))"

rm(examples_path, force=true, recursive=true)

deploydocs(
    repo = "github.com/PALEOtoolkit/PALEOtutorials.jl.git",
)
