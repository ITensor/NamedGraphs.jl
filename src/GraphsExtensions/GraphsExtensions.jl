"""
    module GraphsExtensions

Generic extensions of the Graphs.jl interface.

The functions here are defined against `Graphs.AbstractGraph` rather than
against named graphs, so they work for any graph type, including
`Graphs.SimpleGraph`. They cover subgraphs and vertex/edge removal
(`subgraph`, `rem_vertices!`, `rem_edges!`), trees and forests
(`is_tree`, `root_vertex`, `forest_cover_edge_sequence`), neighborhoods and
boundaries (`incident_edges`, `boundary_vertices`), directedness conversions
(`directed_graph`, `undirected_graph`), graph partitioning backends
(`partition_vertices`), and edge arranging (`arrange_edge`).
"""
module GraphsExtensions
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
