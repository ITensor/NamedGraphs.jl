using Documenter: Documenter, DocMeta, deploydocs, makedocs
using ITensorFormatter: ITensorFormatter
using NamedGraphs: NamedGraphs

DocMeta.setdocmeta!(NamedGraphs, :DocTestSetup, :(using NamedGraphs); recursive = true)

ITensorFormatter.make_index!(pkgdir(NamedGraphs))

makedocs(;
    modules = [NamedGraphs],
    authors = "ITensor developers <support@itensor.org> and contributors",
    sitename = "NamedGraphs.jl",
    format = Documenter.HTML(;
        canonical = "https://itensor.github.io/NamedGraphs.jl",
        edit_link = "main",
        assets = ["assets/favicon.ico", "assets/extras.css"]
    ),
    pages = ["Home" => "index.md", "Reference" => "reference.md"]
)

deploydocs(;
    repo = "github.com/ITensor/NamedGraphs.jl",
    devbranch = "main",
    push_preview = true
)
