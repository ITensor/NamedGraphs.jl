using NamedGraphs
using Test

test_path = joinpath(@__DIR__)

test_files = filter(
  file -> startswith(file, "test_") && endswith(file, ".jl"), readdir(test_path)
)
@testset "NamedGraphs.jl" begin
  @testset "$(last(splitpath(test_path)))" for file in test_files
    file_path = joinpath(test_path, file)
    println("Running test $(file_path)")
    include(file_path)
  end
end
