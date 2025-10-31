using Graphs: Graphs, Edge, add_edge!, add_vertex!, edges, has_edge, has_vertex,
    inneighbors, is_directed, ne, nv, outneighbors, rem_edge!, rem_vertex!, vertices
using .GraphsExtensions: vertextype

# This wrapper reinterprets an AbstractNamedGraph as an AbstractSimpleGraph where the
# integer vertices are the vertex positions (i.e. their position in the ordered
# list of vertices) of the AbstractNamedGraph.
# This is helpful for AbstractNamedGraphs that are implemented directly as opposed to
# as a wrapper around an AbstractSimpleGraph, such as NamedGridGraph.
# The assumption of the wrapper is that `ordered_vertices(g.g)` and `vertex_positions(g.g)`
# for mapping back and forth between vertex names and positions is implemented.
struct PositionGraphView{G <: AbstractGraph} <: AbstractGraph{Int}
    g::G
end
Graphs.is_directed(::Type{<:PositionGraphView{G}}) where {G} = is_directed(G)
Graphs.nv(g::PositionGraphView) = nv(g.g)
Graphs.ne(g::PositionGraphView) = ne(g.g)
Graphs.vertices(g::PositionGraphView) = Base.OneTo(nv(g))
function Graphs.has_vertex(g::PositionGraphView, v::Int)
    return has_vertex(g.g, ordered_vertices(g.g)[v])
end
function Graphs.add_vertex!(g::PositionGraphView, v::Int)
    return add_vertex!(g.g, ordered_vertices(g.g)[v])
end
function Graphs.rem_vertex!(g::PositionGraphView, v::Int)
    return rem_vertex!(g.g, ordered_vertices(g.g)[v])
end
function Graphs.has_edge(g::PositionGraphView, e::Edge)
    return has_edge(g.g, position_edge_to_edge(g.g, e))
end
function Graphs.add_edge!(g::PositionGraphView, e::Edge)
    return add_edge!(g.g, position_edge_to_edge(g.g, e))
end
function Graphs.rem_edge!(g::PositionGraphView, e::Edge)
    return rem_edge!(g.g, position_edge_to_edge(g.g, e))
end
Graphs.edgetype(g::PositionGraphView) = Edge{vertextype(g)}
function Graphs.edges(g::PositionGraphView)
    return Iterators.map(edges(g.g)) do e
        return edge_to_position_edge(g.g, e)
    end
end
function Graphs.outneighbors(g::PositionGraphView, v::Int)
    return map(outneighbors(g.g, ordered_vertices(g.g)[v])) do v′
        return vertex_positions(g.g)[v′]
    end
end
function Graphs.inneighbors(g::PositionGraphView, v::Int)
    return map(inneighbors(g.g, ordered_vertices(g.g)[v])) do v′
        return vertex_positions(g.g)[v′]
    end
end
