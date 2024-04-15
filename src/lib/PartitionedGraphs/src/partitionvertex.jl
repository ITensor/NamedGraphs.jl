struct PartitionVertex{V} <: AbstractPartitionVertex{V}
  vertex::V
end

parent(pv::PartitionVertex) = getfield(pv, :vertex)
