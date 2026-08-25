using Graphs: Graphs, Edge, add_edge!, add_vertex!, edges, has_edge, has_vertex,
    inneighbors, is_directed, ne, nv, outneighbors, rem_edge!, rem_vertex!, vertices

# Reinterprets an AbstractNamedGraph as an AbstractGraph{Int} whose vertices
# are the codes `1:nv(graph)` of the named graph's vertices.
# Default output of `coded_graph(graph::AbstractNamedGraph)` for graph types
# that are implemented directly, as opposed to as a wrapper around a stored
# integer graph, such as NamedGridGraph.
# Assumes `coded_vertex(g.graph, v)` and `decoded_vertex(g.graph, c)` are
# implemented for the wrapped graph.
struct CodedGraphView{G <: AbstractGraph} <: AbstractGraph{Int}
    graph::G
end
Graphs.is_directed(::Type{<:CodedGraphView{G}}) where {G} = is_directed(G)
Graphs.nv(g::CodedGraphView) = nv(g.graph)
Graphs.ne(g::CodedGraphView) = ne(g.graph)
Graphs.vertices(g::CodedGraphView) = Base.OneTo(nv(g))
Graphs.has_vertex(g::CodedGraphView, v::Int) = v ∈ vertices(g)
function Graphs.add_vertex!(g::CodedGraphView, v::Int)
    return add_vertex!(g.graph, decoded_vertex(g.graph, v))
end
function Graphs.rem_vertex!(g::CodedGraphView, v::Int)
    return rem_vertex!(g.graph, decoded_vertex(g.graph, v))
end
function Graphs.has_edge(g::CodedGraphView, e::Edge)
    return has_edge(g.graph, decoded_edge(g.graph, e))
end
function Graphs.add_edge!(g::CodedGraphView, e::Edge)
    return add_edge!(g.graph, decoded_edge(g.graph, e))
end
function Graphs.rem_edge!(g::CodedGraphView, e::Edge)
    return rem_edge!(g.graph, decoded_edge(g.graph, e))
end
Graphs.edgetype(g::CodedGraphView) = Edge{Int}
function Graphs.edges(g::CodedGraphView)
    return Iterators.map(edges(g.graph)) do e
        return coded_edge(g.graph, e)
    end
end
function Graphs.outneighbors(g::CodedGraphView, v::Int)
    return map(outneighbors(g.graph, decoded_vertex(g.graph, v))) do v′
        return coded_vertex(g.graph, v′)
    end
end
function Graphs.inneighbors(g::CodedGraphView, v::Int)
    return map(inneighbors(g.graph, decoded_vertex(g.graph, v))) do v′
        return coded_vertex(g.graph, v′)
    end
end
