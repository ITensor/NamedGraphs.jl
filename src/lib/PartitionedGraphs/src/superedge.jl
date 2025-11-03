using Graphs: Graphs, AbstractEdge, dst, src

struct SuperEdge{V, E <: AbstractEdge{V}} <: AbstractSuperEdge{V}
    edge::E
end

Base.parent(se::SuperEdge) = getfield(se, :edge)
Graphs.src(se::SuperEdge) = SuperVertex(src(parent(se)))
Graphs.dst(se::SuperEdge) = SuperVertex(dst(parent(se)))
SuperEdge(p::Pair) = SuperEdge(NamedEdge(first(p) => last(p)))
SuperEdge(vsrc, vdst) = SuperEdge(vsrc => vdst)
Base.reverse(se::SuperEdge) = SuperEdge(reverse(parent(se)))
