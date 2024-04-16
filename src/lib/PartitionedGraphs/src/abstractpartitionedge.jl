using Graphs: Graphs
using ..NamedGraphs: AbstractNamedEdge

abstract type AbstractPartitionEdge{V} <: AbstractNamedEdge{V} end

Base.parent(pe::AbstractPartitionEdge) = not_implemented()
Graphs.src(pe::AbstractPartitionEdge) = not_implemented()
Graphs.dst(pe::AbstractPartitionEdge) = not_implemented()
Base.reverse(pe::AbstractPartitionEdge) = not_implemented()

#Don't have the vertices wrapped. But wrap them with source and edge.
