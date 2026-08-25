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
    vertices = Iterators.map(decoded_vertex(vs.graph), Base.OneTo(nv(vs.graph)))
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
    return (true, coded_vertex(vs.graph, vertex))
end
Dictionaries.gettokenvalue(vs::VerticesView, token) = decoded_vertex(vs.graph, token)

# Snapshot the vertices so the output does not alias the (mutable) graph.
Base.map(f, vs::VerticesView) = map(f, Indices(collect(vs)))

# Read-only view of the edges of a graph as a set (an `AbstractIndices`),
# iterating through the edges of `coded_graph(graph)` and testing membership
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
        coded_edge -> decoded_edge(es.graph, coded_edge), edges(coded_graph(es.graph))
    )
    return iterate(graph_edges, state...)
end
Base.in(edge::E, es::EdgesView{<:Any, E}) where {E} = has_edge(es.graph, edge)

# Token interface, with coded edges as the tokens.
Dictionaries.istokenizable(es::EdgesView) = true
Dictionaries.tokentype(es::EdgesView) = Edge{Int}
function Dictionaries.iteratetoken(es::EdgesView, state...)
    return iterate(edges(coded_graph(es.graph)), state...)
end
function Dictionaries.gettoken(es::EdgesView, edge)
    has_edge(es.graph, edge) || return (false, Edge(0, 0))
    return (true, coded_edge(es.graph, edge))
end
Dictionaries.gettokenvalue(es::EdgesView, token) = decoded_edge(es.graph, token)

# Snapshot the edges so the output does not alias the (mutable) graph.
Base.map(f, es::EdgesView) = map(f, Indices(collect(es)))

# Read-only view of the vertices of a graph in code order, i.e.
# `DecodedVerticesView(g)[c] == decoded_vertex(g, c)`.
# Default output of `decoded_vertices(graph::AbstractNamedGraph)`.
struct DecodedVerticesView{V, G <: AbstractGraph{V}} <: AbstractVector{V}
    graph::G
end
Base.size(vs::DecodedVerticesView) = (nv(vs.graph),)
Base.getindex(vs::DecodedVerticesView, code::Integer) = decoded_vertex(vs.graph, code)

# Read-only view of the code of each vertex of a graph, i.e.
# `CodedVerticesView(g)[v] == coded_vertex(g, v)`, keyed by `vertices(g)`.
# Default output of `coded_vertices(graph::AbstractNamedGraph)`.
struct CodedVerticesView{V, G <: AbstractGraph{V}} <: AbstractDictionary{V, Int}
    graph::G
end
Base.keys(vs::CodedVerticesView) = vertices(vs.graph)
function Base.getindex(vs::CodedVerticesView{V}, vertex::V) where {V}
    return coded_vertex(vs.graph, vertex)
end
function Base.isassigned(vs::CodedVerticesView{V}, vertex::V) where {V}
    return has_vertex(vs.graph, vertex)
end
