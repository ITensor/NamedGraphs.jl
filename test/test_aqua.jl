using Aqua: Aqua
using NamedGraphs: NamedGraphs
using Test: @testset

@testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(NamedGraphs; undocumented_names = true)
end
