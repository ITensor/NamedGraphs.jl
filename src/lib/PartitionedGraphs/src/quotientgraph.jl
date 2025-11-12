using Graphs: AbstractGraph, rem_vertex!, rem_edge!, vertices, edges
using .GraphsExtensions: add_edges!
using ..NamedGraphs: NamedGraph, position_graph_type

struct QuotientView{V, G <: AbstractGraph} <: AbstractNamedGraph{V}
    graph::G
    QuotientView(graph::G) where {G} = new{quotient_graph_vertextype(G), G}(graph)
end

Base.parent(qg::QuotientView) = qg.graph
parent_graph_type(::Type{<:QuotientView{V, G}}) where {V, G} = G

function Base.convert(GT::Type{<:AbstractGraph}, g::QuotientView)
    qg = GT(vertices(g))
    add_edges!(qg, edges(g))
    return qg
end

NamedGraphs.edgetype(Q::Type{<:QuotientView}) = quotient_graph_edgetype(parent_graph_type(Q))

Graphs.vertices(qg::QuotientView) = parent.(quotientvertices(parent(qg)))
Graphs.edges(qg::QuotientView) = parent.(quotientedges(parent(qg)))

Base.copy(g::QuotientView) = QuotientView(copy(parent(g)))

# Graphs.jl and NamedGraphs.jl interface overloads for `PartitionsGraphView` wrapping
# a `PartitionedGraph`.
function NamedGraphs.position_graph_type(type::Type{<:QuotientView})
    return position_graph_type(quotient_graph_type(parent_graph_type(type)))
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
        :(NamedGraphs.namedgraph_induced_subgraph),
        :(NamedGraphs.ordered_vertices),
        :(NamedGraphs.position_graph),
        :(NamedGraphs.vertex_positions),
    ]
    @eval begin
        function $f(
                g::QuotientView{V, G}, args...; kwargs...
            ) where {V, G}
            return $f(convert(NamedGraph, (g)), args...; kwargs...)
        end
    end
end
