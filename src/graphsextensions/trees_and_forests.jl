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
