using Graphs
using NamedGraphs
using Suppressor
using Test

examples_path = joinpath(pkgdir(NamedGraphs), "examples")
examples_filenames = readdir(examples_path; join=true)
@testset "Run examples: $filename" for filename in examples_filenames
  @suppress include(filename)
end
