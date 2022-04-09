using Graphs
using NamedGraphs
using Test

@testset "README" begin
  filename = joinpath(pkgdir(NamedGraphs), "examples", "README.jl")
  include(filename)
end
