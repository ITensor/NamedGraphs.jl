abstract type AbstractPartitionVertex{V} <: Any where {V} end

#Parent, wrap, unwrap, vertex?
parent(pv::AbstractPartitionVertex) = not_implemented()
