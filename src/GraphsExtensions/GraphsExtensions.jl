"""
    module GraphsExtensions

Generic extensions of the Graphs.jl interface.

The functions here are defined against `Graphs.AbstractGraph` rather than
against named graphs, so they work for any graph type, including
`Graphs.SimpleGraph`. They cover subgraphs and vertex/edge removal
(`subgraph`, `rem_vertices`, `rem_edges!`), trees and forests
(`is_tree`, `root_vertex`, `forest_cover_edge_sequence`), neighborhoods and
boundaries (`incident_edges`, `boundary_vertices`), directedness conversions
(`directed_graph`, `undirected_graph`), graph partitioning backends
(`partition_vertices`), and edge arranging (`arrange_edge`).
"""
module GraphsExtensions

# These mirror the names `NamedGraphs` exports, so downstream never has to name
# this submodule. Everything else stays reachable by qualifying or by
# `using NamedGraphs.GraphsExtensions: name`, and moves here as it gets a
# docstring, which `Aqua.test_all(; undocumented_names = true)` requires.
export add_edges,
    add_edges!, add_vertices, incident_edges, rem_edges, rem_edges!,
    rem_vertices, subgraph

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
