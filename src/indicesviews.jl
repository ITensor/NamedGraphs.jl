using .GraphsExtensions: vertextype
using Dictionaries: Dictionaries, AbstractDictionary, AbstractIndices
using Graphs: AbstractEdge, AbstractEdgeIter, AbstractGraph, Edge, edges, edgetype,
    has_edge, has_vertex, ne, nv

# Read-only view of the vertices of a graph as a set (an `AbstractIndices`),
# iterating in code order and testing membership through `has_vertex`.
# Default output of `vertices(graph::AbstractNamedGraph)`; concrete graph
# types with a stored vertex set can return that directly instead.
# Assumes `has_vertex` is implemented for the wrapped graph (rather than
# falling back to a membership test on `vertices`, which would recurse).
struct NamedVerticesView{V, G <: AbstractGraph{V}} <: AbstractIndices{V}
    graph::G
end

Base.length(vs::NamedVerticesView) = nv(vs.graph)
function Dictionaries.iterate(vs::NamedVerticesView, state...)
    next = iterate(Base.OneTo(nv(vs.graph)), state...)
    isnothing(next) && return nothing
    code, new_state = next
    return decode_vertex(vs.graph, code), new_state
end
Base.in(vertex::V, vs::NamedVerticesView{V}) where {V} = has_vertex(vs.graph, vertex)

# Token interface, with vertex codes as the tokens.
Dictionaries.istokenizable(vs::NamedVerticesView) = true
Dictionaries.tokentype(vs::NamedVerticesView) = Int
function Dictionaries.iteratetoken(vs::NamedVerticesView, state...)
    return iterate(Base.OneTo(nv(vs.graph)), state...)
end
function Dictionaries.iteratetoken_reverse(vs::NamedVerticesView, state...)
    return iterate(reverse(Base.OneTo(nv(vs.graph))), state...)
end
function Dictionaries.gettoken(vs::NamedVerticesView, vertex)
    has_vertex(vs.graph, vertex) || return (false, 0)
    return (true, encode_vertex(vs.graph, vertex))
end
Dictionaries.gettokenvalue(vs::NamedVerticesView, token) = decode_vertex(vs.graph, token)

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
    next = iterate(edges(encoded_graph(es.graph)), state...)
    isnothing(next) && return nothing
    encoded_edge, new_state = next
    return decode_edge(es.graph, encoded_edge), new_state
end
Base.in(edge, es::NamedEdgeIter) = has_edge(es.graph, edge)

# Edge-set equality through `has_edge`, following `SimpleEdgeIter`.
function edge_iter_isequal(es::NamedEdgeIter, edge_collection)
    k = 0
    for e in edge_collection
        e in es || return false
        k += 1
    end
    return k == length(es)
end
Base.:(==)(es1::NamedEdgeIter, es2::NamedEdgeIter) = edge_iter_isequal(es1, es2)
function Base.:(==)(es::NamedEdgeIter, edges::AbstractVector{<:AbstractEdge})
    return edge_iter_isequal(es, edges)
end
function Base.:(==)(edges::AbstractVector{<:AbstractEdge}, es::NamedEdgeIter)
    return edge_iter_isequal(es, edges)
end
Base.:(==)(es::NamedEdgeIter, edges::Set{<:AbstractEdge}) = edge_iter_isequal(es, edges)
Base.:(==)(edges::Set{<:AbstractEdge}, es::NamedEdgeIter) = edge_iter_isequal(es, edges)
Base.show(io::IO, es::NamedEdgeIter) = show(io, collect(es))
