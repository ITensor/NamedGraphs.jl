using NamedGraphs: NamedGraphs, NamedGraphGenerators
using Test: @test, @testset

@testset "Test exports" begin
    @testset "NamedGraphs" begin
        exports = [
            :NamedGraphs,
            :AbstractNamedGraph,
            :NamedDiGraph,
            :NamedEdge,
            :NamedGraph,
        ]
        @test issetequal(names(NamedGraphs), exports)
    end

    @testset "NamedGraphGenerators" begin
        exports = [
            :NamedGraphGenerators,
            :named_binary_tree,
            :named_comb_tree,
            :named_grid,
            :named_hexagonal_lattice_graph,
            :named_path_digraph,
            :named_path_graph,
            :named_triangular_lattice_graph,
        ]
        @test issetequal(names(NamedGraphGenerators), exports)
    end
end
