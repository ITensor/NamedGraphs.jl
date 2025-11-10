using Graphs: AbstractGraph, rem_vertex!, rem_edge!, vertices, edges
using .GraphsExtensions: add_edges!
using ..NamedGraphs: NamedGraph, position_graph_type

struct QuotientView{V, G <: AbstractGraph{V}} <: AbstractNamedGraph{V}
    graph::G
end

Base.parent(qg::QuotientView) = qg.graph
parent_graph_type(::Type{<:QuotientView{V, G}}) where {V, G} = G

function Base.convert(GT::Type{<:AbstractGraph}, g::QuotientView)
    qg = GT(vertices(g))
    add_edges!(qg, edges(g))
    return qg
end

NamedGraphs.vertextype(Q::Type{<:QuotientView}) = quotient_vertextype(parent_graph_type(Q))
NamedGraphs.edgetype(Q::Type{<:QuotientView}) = quotient_edgetype(parent_graph_type(Q))

Graphs.vertices(qg::QuotientView) = quotient_vertices(parent(qg))
Graphs.edges(qg::QuotientView) = quotient_edges(parent(qg))

Base.copy(g::QuotientView) = QuotientView(copy(parent(g)))

# Graphs.jl and NamedGraphs.jl interface overloads for `PartitionsGraphView` wrapping
# a `PartitionedGraph`.
function NamedGraphs.position_graph_type(
        type::Type{<:QuotientView{V, G}}
    ) where {V, G <: PartitionedGraph{V}}
    return position_graph_type(quotient_graph_type(parent_graph_type(type)))
end

function Graphs.rem_vertex!(qg::QuotientView, v)
    rem_supervertex!(parent(qg), SuperVertex(v))
    return qg
end
function Graphs.rem_edge!(qg::QuotientView, v)
    rem_superedge!(parent(qg), SuperEdge(v))
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
