using Aqua: Aqua
using NamedGraphs: NamedGraphs
using Test: @testset

@testset "Code quality (Aqua.jl)" begin
    # TODO: fix and re-enable ambiguity checks
    Aqua.test_all(NamedGraphs; ambiguities = false)
end
