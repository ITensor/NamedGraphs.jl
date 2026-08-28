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
            :add_edge,
            :add_edges,
            :add_edges!,
            :add_vertex,
            :add_vertices,
            :boundary_edges,
            :convert_vertextype,
            :default_root_vertex,
            :directed_graph,
            :disjoint_union,
            :edge_subgraph,
            :edgeless_graph,
            :empty_graph,
            :forest_cover,
            :forest_cover_edge_sequence,
            :in_incident_edges,
            :incident_edges,
            :is_leaf_vertex,
            :leaf_vertices,
            :named_binary_tree,
            :named_comb_tree,
            :named_cycle_graph,
            :named_grid,
            :named_hexagonal_lattice_graph,
            :named_path_digraph,
            :named_path_graph,
            :named_triangular_lattice_graph,
            :post_order_dfs_edges,
            :post_order_dfs_vertices,
            :rem_edge,
            :rem_edges,
            :rem_edges!,
            :rem_vertex,
            :rem_vertices,
            :rename_vertices,
            :similar_graph,
            :spanning_forest,
            :spanning_tree,
            :subgraph,
            :undirected_graph,
            :vertextype,
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
                :to_graph_index,
            ]
        else
            Symbol[]
        end
        @test issetequal(names(NamedGraphs), [exports; public_names])
    end
    @testset "GraphsExtensions" begin
        exports = [
            :GraphsExtensions,
            :boundary_edges,
            :convert_vertextype,
            :default_root_vertex,
            :in_incident_edges,
            :incident_edges,
            :is_leaf_vertex,
            :leaf_vertices,
            :post_order_dfs_edges,
            :post_order_dfs_vertices,
            :similar_graph,
            :subgraph,
            :vertextype,
        ]
        @test issetequal(names(NamedGraphs.GraphsExtensions), exports)
        # Unlike `PartitionedGraphs`, these are also exported from `NamedGraphs`, so
        # downstream does not have to name the submodule.
        @test issubset(setdiff(exports, [:GraphsExtensions]), names(NamedGraphs))
    end
    @testset "PartitionedGraphs" begin
        exports = [
            :AbstractPartitionedGraph,
            :PartitionedGraph,
            :PartitionedGraphs,
            :PartitionedView,
            :QuotientEdge,
            :QuotientEdges,
            :QuotientVertex,
            :QuotientView,
            :quotient_graph,
            :quotientedge,
            :quotientedges,
            :quotientvertices,
            :unpartitioned_graph,
        ]
        # `names` includes `public` names as well as exported ones.
        public_names = if VERSION >= v"1.11.0-DEV.469"
            [
                :boundary_quotientedges,
                :departition,
                :partitioned_vertices,
                :partitionedgraph,
                :unpartition,
            ]
        else
            Symbol[]
        end
        @test issetequal(names(NamedGraphs.PartitionedGraphs), [exports; public_names])
        # `PartitionedGraphs` names are not re-exported from `NamedGraphs`.
        @test isempty(
            intersect(
                setdiff([exports; public_names], [:PartitionedGraphs]), names(NamedGraphs)
            )
        )
    end
end
