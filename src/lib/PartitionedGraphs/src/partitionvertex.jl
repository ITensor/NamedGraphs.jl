struct PartitionVertex{V} <: AbstractPartitionVertex{V}
  vertex::V
end

Base.parent(pv::PartitionVertex) = getfield(pv, :vertex)
