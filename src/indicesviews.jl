using .GraphsExtensions: vertextype
using Dictionaries: Dictionaries, AbstractDictionary, AbstractIndices, Indices
using Graphs: AbstractEdge, AbstractEdgeIter, AbstractGraph, Edge, edges, edgetype,
    has_edge, has_vertex, ne, nv

# Read-only view of the vertices of a graph as a set (an `AbstractIndices`),
# iterating in code order and testing membership through `has_vertex`.
# Default output of `vertices(graph::AbstractNamedGraph)`; concrete graph
# types with a stored vertex set can return that directly instead.
# Assumes `has_vertex` is implemented for the wrapped graph (rather than
# falling back to a membership test on `vertices`, which would recurse).
struct VerticesView{V, G <: AbstractGraph{V}} <: AbstractIndices{V}
    graph::G
end

Base.length(vs::VerticesView) = nv(vs.graph)
function Dictionaries.iterate(vs::VerticesView, state...)
    vertices = Iterators.map(c -> decode_vertex(vs.graph, c), Base.OneTo(nv(vs.graph)))
    return iterate(vertices, state...)
end
Base.in(vertex::V, vs::VerticesView{V}) where {V} = has_vertex(vs.graph, vertex)

# Token interface, with vertex codes as the tokens.
Dictionaries.istokenizable(vs::VerticesView) = true
Dictionaries.tokentype(vs::VerticesView) = Int
function Dictionaries.iteratetoken(vs::VerticesView, state...)
    return iterate(Base.OneTo(nv(vs.graph)), state...)
end
function Dictionaries.iteratetoken_reverse(vs::VerticesView, state...)
    return iterate(reverse(Base.OneTo(nv(vs.graph))), state...)
end
function Dictionaries.gettoken(vs::VerticesView, vertex)
    has_vertex(vs.graph, vertex) || return (false, 0)
    return (true, encode_vertex(vs.graph, vertex))
end
Dictionaries.gettokenvalue(vs::VerticesView, token) = decode_vertex(vs.graph, token)

# Snapshot the vertices so the output does not alias the (mutable) graph.
Base.map(f, vs::VerticesView) = map(f, Indices(collect(vs)))

# Lazy iterator over the edges of a named graph, in the style of
# `Graphs.SimpleGraphs.SimpleEdgeIter`: iterates by decoding the edges of
# `encoded_graph(graph)` and tests membership through `has_edge`.
# Output of `edges(graph::AbstractNamedGraph)`.
struct NamedEdgeIter{V, E <: AbstractEdge{V}, G <: AbstractGraph{V}} <: AbstractEdgeIter
    graph::G
end
function NamedEdgeIter(graph::AbstractGraph)
    return NamedEdgeIter{vertextype(graph), edgetype(graph), typeof(graph)}(graph)
end

Base.eltype(::Type{<:NamedEdgeIter{<:Any, E}}) where {E} = E
Base.length(es::NamedEdgeIter) = ne(es.graph)
function Base.iterate(es::NamedEdgeIter, state...)
    graph_edges = Iterators.map(
        ce -> decode_edge(es.graph, ce), edges(encoded_graph(es.graph))
    )
    return iterate(graph_edges, state...)
end
Base.in(edge, es::NamedEdgeIter) = has_edge(es.graph, edge)
function Base.:(==)(es1::NamedEdgeIter, es2::NamedEdgeIter)
    length(es1) == length(es2) || return false
    return all(e -> e in es2, es1)
end
Base.show(io::IO, es::NamedEdgeIter) = show(io, collect(es))
