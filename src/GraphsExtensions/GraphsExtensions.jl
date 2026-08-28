"""
    module GraphsExtensions

Generic extensions of the Graphs.jl interface.

Most functions here are defined against `Graphs.AbstractGraph` rather than
against named graphs, so they work for any graph type, including
`Graphs.SimpleGraph`. They cover subgraphs (`subgraph`), tree queries and
traversals (`is_leaf_vertex`, `leaf_vertices`, `post_order_dfs_edges`),
neighborhoods and boundaries (`incident_edges`, `boundary_vertices`), and edge
arranging (`arrange_edge`). `partition_vertices` is generic as well, but needs
one of the partitioning backends in `ext/` to be loaded.

The functions that name a vertex or edge to add or remove (`add_vertices`,
`rem_vertices`, `add_edges!`, `rem_edges!`, and so on), and the ones built from
them (`directed_graph`, `edge_subgraph`, `spanning_tree`, `forest_cover`,
`forest_cover_edge_sequence`), are only meaningful for a graph whose vertices
carry names. They are declared here, so the names stay in this module and
existing imports keep working, but their methods are defined on
`AbstractNamedGraph` in `NamedGraphs` itself.
"""
module GraphsExtensions

# These mirror the names `NamedGraphs` exports, so downstream never has to name
# this submodule. Everything else stays reachable by qualifying or by
# `using NamedGraphs.GraphsExtensions: name`, and moves here as it gets a
# docstring, which `Aqua.test_all(; undocumented_names = true)` requires.
export add_edges,
    add_edges!, add_vertices, boundary_edges, convert_vertextype, default_root_vertex,
    directed_graph, forest_cover, forest_cover_edge_sequence, in_incident_edges,
    incident_edges, is_leaf_vertex, leaf_vertices, post_order_dfs_edges,
    post_order_dfs_vertices, rem_edges, rem_edges!, rem_vertices, similar_graph,
    subgraph, undirected_graph, vertextype

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
