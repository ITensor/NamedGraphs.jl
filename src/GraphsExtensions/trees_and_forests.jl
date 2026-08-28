abstract type SpanningTreeAlgorithm end

struct BFS <: SpanningTreeAlgorithm end
struct RandomBFS <: SpanningTreeAlgorithm end
struct DFS <: SpanningTreeAlgorithm end

default_spanning_tree_alg() = BFS()

"""
    default_root_vertex(graph::AbstractGraph)

A vertex of `graph` of maximum eccentricity, used as the default root for
spanning tree constructions and tree traversals.
"""
default_root_vertex(g) = last(findmax(eccentricities(g)))

# Built from `undirected_graph`, `rem_edges` and `similar_dataless_graph`, which
# are named-graph only, so these are as well, with the methods in NamedGraphs
# proper.
function spanning_tree end
function spanning_forest end
function forest_cover end
function forest_cover_edge_sequence end
