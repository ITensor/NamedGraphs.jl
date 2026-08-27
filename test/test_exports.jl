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
            :incident_edges,
            :named_binary_tree,
            :named_comb_tree,
            :named_cycle_graph,
            :named_grid,
            :named_hexagonal_lattice_graph,
            :named_path_digraph,
            :named_path_graph,
            :named_triangular_lattice_graph,
            :rename_vertices,
            :subgraph,
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
    @testset "PartitionedGraphs" begin
        exports = [
            :AbstractPartitionedGraph,
            :PartitionedGraph,
            :PartitionedGraphs,
            :PartitionedView,
            :QuotientEdge,
            :QuotientVertex,
            :QuotientView,
            :boundary_quotientedges,
            :departition,
            :has_quotientedge,
            :has_quotientvertex,
            :is_partition_boundary_edge,
            :partitionedgraph,
            :quotientedge,
            :quotientedges,
            :quotientvertices,
            :quotientview,
            :rem_quotientedge!,
            :rem_quotientvertex!,
            :unpartition,
        ]
        @test issetequal(names(NamedGraphs.PartitionedGraphs), exports)
        # `PartitionedGraphs` names are not re-exported from `NamedGraphs`.
        @test isempty(intersect(setdiff(exports, [:PartitionedGraphs]), names(NamedGraphs)))
    end
end
