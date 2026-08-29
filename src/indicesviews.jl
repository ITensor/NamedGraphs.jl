using Dictionaries: Dictionaries, AbstractDictionary, AbstractIndices
using Graphs: AbstractEdge, AbstractEdgeIter, AbstractGraph, Edge, edges, edgetype,
    has_edge, has_vertex, ne, nv

# Read-only view of the vertices of a graph as a set (an `AbstractIndices`),
# iterating in code order and testing membership through `has_vertex`.
# Default output of `vertices(graph::AbstractNamedGraph)`. Mutable graph types
# with a stored vertex set should return that directly instead so that
# iteration follows insertion order, as `NamedGraph` and `NamedDiGraph` do (for immutable
# graph types like `NamedGridGraph`, code order and insertion order coincide).
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
    return decoded_vertex(vs.graph, code), new_state
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
    return (true, encoded_vertex(vs.graph, vertex))
end
Dictionaries.gettokenvalue(vs::NamedVerticesView, token) = decoded_vertex(vs.graph, token)

# Lazy iterator over the edges of a named graph, in the style of
# `Graphs.SimpleGraphs.SimpleEdgeIter`: iterates by decoding the edges of
# `encoded_graph(graph)` and tests membership through `has_edge`.
# Output of `edges(graph::AbstractNamedGraph)`.
struct NamedEdgeIter{V, E <: AbstractNamedEdge{V}, G <: AbstractNamedGraph{V}} <:
    AbstractEdgeIter
    graph::G
end
function NamedEdgeIter(graph::AbstractNamedGraph)
    return NamedEdgeIter{vertextype(graph), edgetype(graph), typeof(graph)}(graph)
end

Base.eltype(::Type{<:NamedEdgeIter{<:Any, E}}) where {E} = E
Base.length(es::NamedEdgeIter) = ne(es.graph)
function Base.iterate(es::NamedEdgeIter, state...)
    next = iterate(edges(encoded_graph(es.graph)), state...)
    isnothing(next) && return nothing
    encoded_edge, new_state = next
    return decoded_edge(es.graph, encoded_edge), new_state
end
Base.in(edge, es::NamedEdgeIter) = has_edge(es.graph, edge)

# Edge-set equality through `has_edge`. Codes are not comparable across
# graphs, so this compares the named edges rather than the encoded graphs.
function Base.:(==)(es1::NamedEdgeIter, es2::NamedEdgeIter)
    length(es1) == length(es2) || return false
    return all(e -> e in es2, es1)
end
Base.show(io::IO, es::NamedEdgeIter) = show(io, collect(es))

# Lazy iterator over both directions of each edge of an undirected named graph.
# Output of `all_edges(graph)` there. Built as an iterator rather than a
# `Iterators.flatten` so that `eltype` and `length` survive: flattening drops
# both, which breaks callers that dispatch on the element type.
struct NamedAllEdgeIter{V, E <: AbstractNamedEdge{V}, G <: AbstractNamedGraph{V}} <:
    AbstractEdgeIter
    graph::G
end
function NamedAllEdgeIter(graph::AbstractNamedGraph)
    return NamedAllEdgeIter{vertextype(graph), edgetype(graph), typeof(graph)}(graph)
end

Base.eltype(::Type{<:NamedAllEdgeIter{<:Any, E}}) where {E} = E
Base.length(es::NamedAllEdgeIter) = 2 * ne(es.graph)
# The state carries the reversed edge still owed for the current forward edge,
# so each edge is emitted immediately before its reverse.
function Base.iterate(es::NamedAllEdgeIter)
    next = iterate(edges(es.graph))
    isnothing(next) && return nothing
    edge, edges_state = next
    return edge, (edges_state, reverse(edge))
end
function Base.iterate(es::NamedAllEdgeIter, state)
    edges_state, owed = state
    isnothing(owed) || return owed, (edges_state, nothing)
    next = iterate(edges(es.graph), edges_state)
    isnothing(next) && return nothing
    edge, new_state = next
    return edge, (new_state, reverse(edge))
end
Base.in(edge, es::NamedAllEdgeIter) = has_edge(es.graph, edge)
Base.show(io::IO, es::NamedAllEdgeIter) = show(io, collect(es))
