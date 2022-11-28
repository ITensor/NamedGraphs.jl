# Represents converting a vertex to the type expected for
# a graph or edge.
# Helpful for generic code with multi-dimensional indexing
# of graphs and edges.
to_vertex(::Type, v...) = v
to_vertex(e::AbstractEdge, v...) = to_vertex(typeof(e), v...)
to_vertex(g::AbstractGraph, v...) = to_vertex(typeof(g), v...)
