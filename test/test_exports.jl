using NamedGraphs: NamedGraphs
using Test: @test, @testset

@testset "Test exports" begin
    @testset "NamedGraphs" begin
        exports = [
            :⊔,
            :NamedGraphs,
            :AbstractNamedGraph,
            :NamedDiGraph,
            :NamedEdge,
            :NamedGraph,
        ]
        @test issetequal(names(NamedGraphs), exports)
    end
end
