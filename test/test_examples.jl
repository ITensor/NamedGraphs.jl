using Graphs
using NamedGraphs
using Suppressor
using Test

examples_path = joinpath(pkgdir(NamedGraphs), "examples")
@testset "Run examples: $filename" for filename in readdir(examples_path)
  if endswith(filename, ".jl")
    @suppress include(joinpath(examples_path, filename))
  end
end
