using Graphs
using NamedGraphs
using Suppressor
using Test

examples_path = joinpath(pkgdir(NamedGraphs), "examples")
examples_to_exclude = ["partitioning.jl"]
@testset "Run examples: $filename" for filename in
                                       setdiff(readdir(examples_path), examples_to_exclude)
  if endswith(filename, ".jl")
    @suppress include(joinpath(examples_path, filename))
  end
end
