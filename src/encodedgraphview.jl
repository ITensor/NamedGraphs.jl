using Graphs: Graphs, AbstractGraph, Edge, SimpleDiGraph, SimpleGraph, add_edge!,
    add_vertex!, blockdiag, edges, has_edge, has_vertex, inneighbors, is_directed, ne, nv,
    outneighbors, rem_edge!, rem_vertex!, vertices

"""
    EncodedGraphView(graph::AbstractNamedGraph)

An `AbstractGraph{Int}` presenting `graph` on its vertex codes `1:nv(graph)`, for
graph types that compute their topology directly rather than storing an integer
graph. Such a type returns `EncodedGraphView(graph)` from [`encoded_graph`](@ref)
and must define `nv`, `ne`, `has_vertex`, `has_edge`, `edges`, and the neighbor
hooks itself, since the view answers every query by asking `graph`.
`NamedGridGraph` is an example.
"""
struct EncodedGraphView{G <: AbstractGraph} <: AbstractGraph{Int}
    graph::G
end
Graphs.is_directed(::Type{<:EncodedGraphView{G}}) where {G} = is_directed(G)
Graphs.nv(g::EncodedGraphView) = nv(g.graph)
Graphs.ne(g::EncodedGraphView) = ne(g.graph)
Graphs.vertices(g::EncodedGraphView) = Base.OneTo(nv(g))
Graphs.has_vertex(g::EncodedGraphView, v::Int) = v ∈ vertices(g)
function Graphs.add_vertex!(g::EncodedGraphView, v::Int)
    return add_vertex!(g.graph, decoded_vertex(g.graph, v))
end
function Graphs.rem_vertex!(g::EncodedGraphView, v::Int)
    return rem_vertex!(g.graph, decoded_vertex(g.graph, v))
end
Graphs.has_edge(g::EncodedGraphView, s::Int, d::Int) = has_edge(g, Edge(s, d))
function Graphs.has_edge(g::EncodedGraphView, e::Edge)
    return has_edge(g.graph, decoded_edge(g.graph, e))
end
function Graphs.add_edge!(g::EncodedGraphView, e::Edge)
    return add_edge!(g.graph, decoded_edge(g.graph, e))
end
function Graphs.rem_edge!(g::EncodedGraphView, e::Edge)
    return rem_edge!(g.graph, decoded_edge(g.graph, e))
end
Graphs.edgetype(g::EncodedGraphView) = Edge{Int}

# A view has no storage of its own, so its copy is a graph that does, as
# `copy(::SubArray)` gives an `Array`.
Base.copy(g::EncodedGraphView) = (is_directed(g) ? SimpleDiGraph : SimpleGraph)(g)

# Graphs.jl builds the result of `blockdiag` with `T(n)` for the operand type `T`,
# which a view cannot provide, so a view operand is materialized first.
Graphs.blockdiag(g::EncodedGraphView, h::EncodedGraphView) = blockdiag(copy(g), copy(h))
Graphs.blockdiag(g::EncodedGraphView, h::AbstractGraph) = blockdiag(copy(g), h)
Graphs.blockdiag(g::AbstractGraph, h::EncodedGraphView) = blockdiag(g, copy(h))
function Graphs.edges(g::EncodedGraphView)
    return Iterators.map(edges(g.graph)) do e
        return encoded_edge(g.graph, e)
    end
end
function Graphs.outneighbors(g::EncodedGraphView, v::Int)
    return map(outneighbors(g.graph, decoded_vertex(g.graph, v))) do v′
        return encoded_vertex(g.graph, v′)
    end
end
function Graphs.inneighbors(g::EncodedGraphView, v::Int)
    return map(inneighbors(g.graph, decoded_vertex(g.graph, v))) do v′
        return encoded_vertex(g.graph, v′)
    end
end
