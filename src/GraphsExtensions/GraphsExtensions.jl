"""
    module GraphsExtensions

Generic extensions of the Graphs.jl interface.

Covers subgraphs, tree queries and traversals, neighborhoods and boundaries,
edge arranging, and vertex partitioning. Most of it is defined against
`Graphs.AbstractGraph` rather than against named graphs, so it works for any
graph type, including `Graphs.SimpleGraph`.
"""
module GraphsExtensions

# These mirror the names `NamedGraphs` exports, so downstream never has to name
# this submodule. Everything else stays reachable by qualifying or by
# `using NamedGraphs.GraphsExtensions: name`, and moves here as it gets a
# docstring, which `Aqua.test_all(; undocumented_names = true)` requires.
export boundary_edges,
    convert_vertextype, default_root_vertex, in_incident_edges, incident_edges,
    is_leaf_vertex, leaf_vertices, post_order_dfs_edges, post_order_dfs_vertices,
    similar_graph, subgraph, vertextype

include("graphgenerators.jl")
include("abstractgraph.jl")
include("abstracttrees.jl")
include("boundary.jl")
include("neighbors.jl")
include("shortestpaths.jl")
include("symrcm.jl")
include("partitioning.jl")
include("trees_and_forests.jl")
include("simplegraph.jl")
include("arrange_edges.jl")
end
