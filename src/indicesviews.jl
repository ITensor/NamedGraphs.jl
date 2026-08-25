using .GraphsExtensions: vertextype
using Dictionaries: Dictionaries, AbstractDictionary, AbstractIndices, Indices
using Graphs:
    AbstractEdge, AbstractGraph, Edge, edges, edgetype, has_edge, has_vertex, ne, nv

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

# Read-only view of the edges of a graph as a set (an `AbstractIndices`),
# iterating through the edges of `encode_graph(graph)` and testing membership
# through `has_edge`. Output of `edges(graph::AbstractNamedGraph)`.
struct EdgesView{V, E <: AbstractEdge{V}, G <: AbstractGraph{V}} <: AbstractIndices{E}
    graph::G
end
function EdgesView(graph::AbstractGraph)
    return EdgesView{vertextype(graph), edgetype(graph), typeof(graph)}(graph)
end

Base.length(es::EdgesView) = ne(es.graph)
function Dictionaries.iterate(es::EdgesView, state...)
    graph_edges = Iterators.map(
        ce -> decode_edge(es.graph, ce), edges(encode_graph(es.graph))
    )
    return iterate(graph_edges, state...)
end
Base.in(edge::E, es::EdgesView{<:Any, E}) where {E} = has_edge(es.graph, edge)

# Token interface, with coded edges as the tokens.
Dictionaries.istokenizable(es::EdgesView) = true
Dictionaries.tokentype(es::EdgesView) = Edge{Int}
function Dictionaries.iteratetoken(es::EdgesView, state...)
    return iterate(edges(encode_graph(es.graph)), state...)
end
function Dictionaries.gettoken(es::EdgesView, edge)
    has_edge(es.graph, edge) || return (false, Edge(0, 0))
    return (true, encode_edge(es.graph, edge))
end
Dictionaries.gettokenvalue(es::EdgesView, token) = decode_edge(es.graph, token)

# Snapshot the edges so the output does not alias the (mutable) graph.
Base.map(f, es::EdgesView) = map(f, Indices(collect(es)))
