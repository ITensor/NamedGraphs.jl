using Graphs: Graphs, AbstractGraph, ne, has_edge, rem_edge!
using ..NamedGraphs.GraphsExtensions: GraphsExtensions, not_implemented, rem_edges!, rem_edge
using ..NamedGraphs: AbstractNamedEdge

abstract type AbstractSuperEdge{V} <: AbstractNamedEdge{V} end

Base.parent(::AbstractSuperEdge) = not_implemented()
Graphs.src(::AbstractSuperEdge) = not_implemented()
Graphs.dst(::AbstractSuperEdge) = not_implemented()
Base.reverse(::AbstractSuperEdge) = not_implemented()

function Graphs.has_edge(g::AbstractGraph, se::AbstractSuperEdge)
    return parent(se) in quotient_edges(g)
end

Graphs.ne(g::AbstractGraph, se::AbstractSuperEdge) = length(quotient_edges(g, se))

function Graphs.rem_edge!(g::AbstractGraph, se::AbstractSuperEdge)
    edges_to_remove = partitioned_edges(g, se)
    rem_edges!(g, edges_to_remove)
    return g
end

GraphsExtensions.rem_edge(g, sv) = rem_edge!(copy(g), sv)
