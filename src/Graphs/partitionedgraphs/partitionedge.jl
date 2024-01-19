struct PartitionEdge{V,E<:AbstractEdge{<:V}} <: AbstractPartitionEdge{V}
  edge::E
end

parent(pe::PartitionEdge) = getfield(pe, :edge)
src(pe::PartitionEdge) = PartitionVertex(src(parent(pe)))
dst(pe::PartitionEdge) = PartitionVertex(dst(parent(pe)))
PartitionEdge(p::Pair) = PartitionEdge(NamedEdge(first(p) => last(p)))
PartitionEdge(vsrc, vdst) = PartitionEdge(vsrc => vdst)
reverse(pe::PartitionEdge) = PartitionEdge(reverse(parent(pe)))
