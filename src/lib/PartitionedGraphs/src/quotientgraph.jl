using Graphs: AbstractGraph, rem_vertex!, vertices, edges
using .GraphsExtensions: add_edges!
using ..NamedGraphs: NamedGraph, position_graph_type

struct QuotientView{V, G <: AbstractGraph{V}} <: AbstractNamedGraph{V}
    graph::G
end

function quotient_graph(g::QuotientView)
    qg = NamedGraph(vertices(g))
    add_edges!(qg, edges(g))
    return qg
end

quotient_graph_type(::Type{<:QuotientView{V}}) where {V} = NamedGraph{V}

Graphs.vertices(qg::QuotientView) = quotient_vertices(qg.graph)
Graphs.edges(qg::QuotientView) = quotient_edges(qg.graph)

Base.copy(g::QuotientView) = QuotientView(copy(g.graph))

# Graphs.jl and NamedGraphs.jl interface overloads for `PartitionsGraphView` wrapping
# a `PartitionedGraph`.
function NamedGraphs.position_graph_type(
        type::Type{<:QuotientView{V, G}}
    ) where {V, G <: PartitionedGraph{V}}
    return position_graph_type(quotient_graph_type(type))
end

function Graphs.rem_vertex!(qg::QuotientView, v)
    g = qg.graph
    rem_vertex!(g, super_vertex_type(g)(v))
end
function Graphs.rem_edge!(qg::QuotientView, v)
    g = qg.graph
    rem_edge!(g, super_edge_type(g)(v))
end

function Graphs.add_vertex!(qg::QuotientView, v)
    g = qg.graph
    add_vertex!(g, super_vertex_type(g)(v))
end
function Graphs.add_edge!(qg::QuotientView, v)
    g = qg.graph
    add_edge!(g, super_edge_type(g)(v))
end

for f in [
        :(NamedGraphs.edgetype),
        :(NamedGraphs.namedgraph_induced_subgraph),
        :(NamedGraphs.ordered_vertices),
        :(NamedGraphs.position_graph),
        :(NamedGraphs.vertex_positions),
        :(NamedGraphs.vertextype),
    ]
    @eval begin
        function $f(
                g::QuotientView{V, G}, args...; kwargs...
            ) where {V, G}
            return $f(quotient_graph(g), args...; kwargs...)
        end
    end
end

