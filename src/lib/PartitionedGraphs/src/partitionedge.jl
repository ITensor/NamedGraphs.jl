using Graphs: Graphs, AbstractEdge, dst, src

struct PartitionEdge{V, E <: AbstractEdge{V}} <: AbstractPartitionEdge{V}
    edge::E
end

Base.parent(pe::PartitionEdge) = getfield(pe, :edge)
Graphs.src(pe::PartitionEdge) = PartitionVertex(src(parent(pe)))
Graphs.dst(pe::PartitionEdge) = PartitionVertex(dst(parent(pe)))
PartitionEdge(p::Pair) = PartitionEdge(NamedEdge(first(p) => last(p)))
PartitionEdge(vsrc, vdst) = PartitionEdge(vsrc => vdst)
Base.reverse(pe::PartitionEdge) = PartitionEdge(reverse(parent(pe)))
