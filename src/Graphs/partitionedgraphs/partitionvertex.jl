struct PartitionVertex{V} <: AbstractPartitionVertex{V}
  vertex::V
end

underlying_vertex(pv::PartitionVertex) = getfield(pv, :vertex)
