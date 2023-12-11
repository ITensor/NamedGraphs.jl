abstract type AbstractPartitionEdge{V} <: AbstractNamedEdge{V} end

edge(pe::AbstractPartitionEdge) = not_implemented()

src(pe::AbstractPartitionEdge) = src(edge(pe))
dst(pe::AbstractPartitionEdge) = dst(edge(pe))
