using NamedGraphs: NamedGraphs
using Test: @test, @testset

@testset "Test exports" begin
    @testset "NamedGraphs" begin
        exports = [
            :AbstractNamedGraph,
            :NamedDiGraph,
            :NamedEdge,
            :NamedGraph,
            :NamedGraphs,
            :disjoint_union,
            :named_binary_tree,
            :named_comb_tree,
            :named_cycle_graph,
            :named_grid,
            :named_hexagonal_lattice_graph,
            :named_path_digraph,
            :named_path_graph,
            :named_triangular_lattice_graph,
            :rename_vertices,
            :⊔,
        ]
        # `names` includes `public` names as well as exported ones.
        public_names = if VERSION >= v"1.11.0-DEV.469"
            [
                :GraphsExtensions,
                :PartitionedGraphs,
                :decode_edge,
                :decode_vertex,
                :encode_edge,
                :encode_vertex,
                :encoded_graph,
            ]
        else
            Symbol[]
        end
        @test issetequal(names(NamedGraphs), [exports; public_names])
    end
end
