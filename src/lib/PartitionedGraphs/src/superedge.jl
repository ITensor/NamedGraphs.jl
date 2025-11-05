using Graphs: AbstractGraph, Graphs, AbstractEdge, dst, src, ne
using ..NamedGraphs: AbstractNamedEdge
using ..NamedGraphs.GraphsExtensions: GraphsExtensions, not_implemented, rem_edges!, rem_edge

struct SuperEdge{V, E <: AbstractEdge{V}} <: AbstractNamedEdge{V}
    edge::E
end

Base.parent(se::SuperEdge) = getfield(se, :edge)
Graphs.src(se::SuperEdge) = SuperVertex(src(parent(se)))
Graphs.dst(se::SuperEdge) = SuperVertex(dst(parent(se)))
SuperEdge(p::Pair) = SuperEdge(NamedEdge(first(p) => last(p)))
SuperEdge(vsrc, vdst) = SuperEdge(vsrc => vdst)
Base.reverse(se::SuperEdge) = SuperEdge(reverse(parent(se)))

function Graphs.has_edge(g::AbstractGraph, se::SuperEdge)
    return parent(se) in quotient_edges(g)
end

Graphs.ne(g::AbstractGraph, se::SuperEdge) = length(quotient_edges(g, se))

function Graphs.rem_edge!(g::AbstractGraph, se::SuperEdge)
    edges_to_remove = partitioned_edges(g, se)
    rem_edges!(g, edges_to_remove)
    return g
end
