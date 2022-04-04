using NamedGraphs
using Documenter

DocMeta.setdocmeta!(NamedGraphs, :DocTestSetup, :(using NamedGraphs); recursive=true)

makedocs(;
  modules=[NamedGraphs],
  authors="Matthew Fishman <mfishman@flatironinstitute.org> and contributors",
  repo="https://github.com/mtfishman/NamedGraphs.jl/blob/{commit}{path}#{line}",
  sitename="NamedGraphs.jl",
  format=Documenter.HTML(;
    prettyurls=get(ENV, "CI", "false") == "true",
    canonical="https://mtfishman.github.io/NamedGraphs.jl",
    assets=String[],
  ),
  pages=["Home" => "index.md"],
)

deploydocs(; repo="github.com/mtfishman/NamedGraphs.jl", devbranch="main")
