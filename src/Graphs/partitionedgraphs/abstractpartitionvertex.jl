abstract type AbstractPartitionVertex{V} <: Any where {V} end

underlying_vertex(pv::AbstractPartitionVertex) = not_implemented()
