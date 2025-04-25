using NamedGraphs: NamedGraphs
using Documenter: Documenter, DocMeta, deploydocs, makedocs

DocMeta.setdocmeta!(NamedGraphs, :DocTestSetup, :(using NamedGraphs); recursive=true)

include("make_index.jl")

makedocs(;
  modules=[NamedGraphs],
  authors="ITensor developers <support@itensor.org> and contributors",
  sitename="NamedGraphs.jl",
  format=Documenter.HTML(;
    canonical="https://itensor.github.io/NamedGraphs.jl",
    edit_link="main",
    assets=["assets/favicon.ico", "assets/extras.css"],
  ),
  pages=["Home" => "index.md", "Reference" => "reference.md"],
)

deploydocs(; repo="github.com/ITensor/NamedGraphs.jl", devbranch="main", push_preview=true)
