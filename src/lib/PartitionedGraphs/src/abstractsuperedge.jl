using Graphs: Graphs
using ..NamedGraphs: AbstractNamedEdge

abstract type AbstractSuperEdge{V} <: AbstractNamedEdge{V} end

Base.parent(se::AbstractSuperEdge) = not_implemented()
Graphs.src(se::AbstractSuperEdge) = not_implemented()
Graphs.dst(se::AbstractSuperEdge) = not_implemented()
Base.reverse(se::AbstractSuperEdge) = not_implemented()

#Don't have the vertices wrapped. But wrap them with source and edge.
