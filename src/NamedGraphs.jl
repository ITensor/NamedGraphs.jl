"""
    NamedGraphs

An extension of [Graphs.jl](https://github.com/JuliaGraphs/Graphs.jl) providing
graph types with named vertices. The vertices of a [`NamedGraph`](@ref) or
[`NamedDiGraph`](@ref) can be strings, tuples, or any other names, rather than
the contiguous integers of a `Graphs.SimpleGraph`. Named graphs aim to implement
the functionality of Graphs.jl accounting for named vertices and edges, so see
the [Graphs.jl documentation](https://juliagraphs.org/Graphs.jl/stable/) for the
available functionality. Not all of it is wrapped yet: for performance, functions
are usually implemented by translating to the integer vertices and forwarding to
the Graphs.jl implementation, which assumes contiguous integer vertices, so they
have to be wrapped one at a time. Please raise an issue if functionality you need
is missing.

See also [`NamedGraphs.PartitionedGraphs`](@ref) for partitioned graphs and their
quotient graphs.
"""
module NamedGraphs

# `add_vertices!` and `rem_vertices!` are deliberately not exported: Graphs.jl
# exports its own, different, generic functions under those names, so exporting
# ours would leave both dead after `using Graphs, NamedGraphs`.
export ⊔, AbstractNamedGraph, NamedDiGraph, NamedEdge, NamedGraph,
    add_edges, add_edges!, add_vertices, boundary_edges, convert_vertextype,
    default_root_vertex, directed_graph, disjoint_union, forest_cover,
    forest_cover_edge_sequence, in_incident_edges, incident_edges, is_leaf_vertex,
    leaf_vertices, named_binary_tree, named_comb_tree, named_cycle_graph, named_grid,
    named_hexagonal_lattice_graph, named_path_digraph, named_path_graph,
    named_triangular_lattice_graph, post_order_dfs_edges, post_order_dfs_vertices,
    rem_edges, rem_edges!, rem_vertices, rename_vertices, similar_graph, subgraph,
    undirected_graph, vertextype
if VERSION >= v"1.11.0-DEV.469"
    eval(Meta.parse("public GraphsExtensions, PartitionedGraphs"))
    # The encode and decode interface is what a new `AbstractNamedGraph` overloads,
    # so it is public rather than exported.
    # `to_graph_index` is an indexing extension point that graph and index types
    # overload, so it is public rather than exported.
    eval(
        Meta.parse(
            "public decode_edge, decode_vertex, encode_edge, encode_vertex, encoded_graph, to_graph_index"
        )
    )
end

include("similartype.jl")
include("GraphsExtensions/GraphsExtensions.jl")
# The `GraphsExtensions` names re-exported below, listed here rather than relying
# on the per-file imports that happen to bring them into scope.
using .GraphsExtensions: boundary_edges, convert_vertextype, default_root_vertex,
    in_incident_edges, incident_edges, is_leaf_vertex, leaf_vertices, post_order_dfs_edges,
    post_order_dfs_vertices, similar_graph, subgraph, vertextype
include("utils.jl")
include("abstractnamededge.jl")
include("namededge.jl")
include("abstractnamedgraph.jl")
include("graph_unions.jl")
include("indicesviews.jl")
include("abstractgraphindices.jl")
include("similar_graph.jl")
include("decorate.jl")
include("shortestpaths.jl")
include("distance.jl")
include("distances_and_capacities.jl")
include("steiner_tree.jl")
include("dfs.jl")
include("trees_and_forests.jl")
include("namedgraph.jl")
include("encodedgraphview.jl")
include("simplecycles.jl")
include("namedgraphgenerators.jl")
include("namedgridgraph.jl")
include("PartitionedGraphs/PartitionedGraphs.jl")

end
