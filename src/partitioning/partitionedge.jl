struct PartitionEdge{V,E<:AbstractEdge{V}} <: AbstractPartitionEdge{V}
  edge::E
end

edge(pe::PartitionEdge) = getfield(pe, :edge)
src(pe::PartitionEdge) = PartitionVertex(src(edge(pe)))
dst(pe::PartitionEdge) = PartitionVertex(dst(edge(pe)))
PartitionEdge(p::Pair) = PartitionEdge(NamedEdge(p.first => p.second))
