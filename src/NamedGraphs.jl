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

See also [`PartitionedGraphs`](@ref) for partitioned graphs and their quotient
graphs, and [`GraphsExtensions`](@ref) for extensions that apply to any
`Graphs.AbstractGraph`.
"""
module NamedGraphs

# `add_vertices!` and `rem_vertices!` are deliberately not exported: Graphs.jl
# exports its own, different, generic functions under those names, so exporting
# ours would leave both dead after `using Graphs, NamedGraphs`.
export ⊔, AbstractNamedGraph, NamedDiGraph, NamedEdge, NamedGraph,
    add_edges, add_edges!, add_vertices, disjoint_union, incident_edges,
    named_binary_tree, named_comb_tree, named_cycle_graph, named_grid,
    named_hexagonal_lattice_graph, named_path_digraph, named_path_graph,
    named_triangular_lattice_graph, rem_edges, rem_edges!, rem_vertices,
    rename_vertices, subgraph
if VERSION >= v"1.11.0-DEV.469"
    eval(Meta.parse("public GraphsExtensions, PartitionedGraphs"))
    # The encode and decode interface is what a new `AbstractNamedGraph` overloads,
    # so it is public rather than exported.
    eval(
        Meta.parse(
            "public decode_edge, decode_vertex, encode_edge, encode_vertex, encoded_graph"
        )
    )
end

include("similartype.jl")
include("GraphsExtensions/GraphsExtensions.jl")
# The `GraphsExtensions` names re-exported below, listed here rather than relying
# on the per-file imports that happen to bring them into scope.
using .GraphsExtensions: add_edges, add_edges!, add_vertices, incident_edges, rem_edges,
    rem_edges!, rem_vertices, subgraph
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
include("namedgraph.jl")
include("encodedgraphview.jl")
include("simplecycles.jl")
include("namedgraphgenerators.jl")
include("namedgridgraph.jl")
include("PartitionedGraphs/PartitionedGraphs.jl")

end
