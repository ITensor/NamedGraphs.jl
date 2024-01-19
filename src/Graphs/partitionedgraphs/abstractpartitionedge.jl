abstract type AbstractPartitionEdge{V} <: AbstractNamedEdge{V} end

parent(pe::AbstractPartitionEdge) = not_implemented()
src(pe::AbstractPartitionEdge) = not_implemented()
dst(pe::AbstractPartitionEdge) = not_implemented()
reverse(pe::AbstractPartitionEdge) = not_implemented()

#Don't have the vertices wrapped. But wrap them with source and edge.
