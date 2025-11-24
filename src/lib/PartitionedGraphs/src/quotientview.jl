using Graphs: AbstractGraph, rem_vertex!, rem_edge!, vertices, edges
using ..NamedGraphs: NamedGraph, position_graph_type
using .GraphsExtensions: directed_graph_type, undirected_graph_type
using ..SimilarType: similar_type

struct QuotientView{V, G <: AbstractGraph} <: AbstractNamedGraph{V}
    graph::G
    QuotientView(graph::G) where {G} = new{quotient_graph_vertextype(graph), G}(graph)
end

Base.parent(qg::QuotientView) = qg.graph
parent_graph_type(g::AbstractGraph) = parent_graph_type(typeof(g))
parent_graph_type(::Type{<:QuotientView{V, G}}) where {V, G} = G

Base.copy(qv::QuotientView) = copy(quotient_graph(parent(qv)))

NamedGraphs.edgetype(Q::Type{<:QuotientView}) = quotient_graph_edgetype(parent_graph_type(Q))

Graphs.vertices(qg::QuotientView) = keys(partitioned_vertices(parent(qg)))
Graphs.edges(qg::QuotientView) = edges(quotient_graph(parent(qg)))

function NamedGraphs.position_graph_type(type::Type{<:QuotientView})
    return position_graph_type(quotient_graph_type(parent_graph_type(type)))
end

function NamedGraphs.GraphsExtensions.directed_graph_type(type::Type{<:QuotientView})
    return directed_graph_type(quotient_graph_type(parent_graph_type(type)))
end
function NamedGraphs.GraphsExtensions.undirected_graph_type(type::Type{<:QuotientView})
    return undirected_graph_type(quotient_graph_type(parent_graph_type(type)))
end

function Graphs.rem_vertex!(qg::QuotientView, v)
    rem_quotientvertex!(parent(qg), QuotientVertex(v))
    return qg
end
function Graphs.rem_edge!(qg::QuotientView, v)
    rem_quotientedge!(parent(qg), QuotientEdge(v))
    return qg
end

for f in [
        :(NamedGraphs.induced_subgraph_from_vertices),
        :(NamedGraphs.ordered_vertices),
        :(NamedGraphs.vertex_positions),
        :(NamedGraphs.position_graph),
    ]
    @eval begin
        function $f(g::QuotientView, args...; kwargs...)
            return $f(copy(g), args...; kwargs...)
        end
    end
end

function NamedGraphs.SimilarType.similar_type(type::Type{<:QuotientView})
    return similar_type(quotient_graph_type(parent_graph_type(type)))
end

quotientview(g::AbstractGraph) = QuotientView(g)
