using Graphs: AbstractGraph, Graphs, AbstractEdge, dst, src, ne
using ..NamedGraphs: AbstractNamedEdge
using ..NamedGraphs.GraphsExtensions: GraphsExtensions, not_implemented, rem_edges!, rem_edge

struct SuperEdge{V, E <: AbstractEdge{V}} <: AbstractNamedEdge{V}
    edge::E
end

superedge(pg::AbstractGraph, edge::AbstractEdge) = SuperEdge(find_quotient_edge(pg, edge))
superedge(pg::AbstractGraph, p::Pair) = superedge(pg, edgetype(pg)(p))

"""
    superedges(pg::AbstractPartitionedGraph, es = edges(pg))

Return all unique super edges corresponding to the set edges `es` of the graph `pg`.
"""
superedges(pg::AbstractGraph) = SuperEdge.(quotient_edges(pg))
function superedges(pg::AbstractGraph, es)
    return filter!(!is_self_loop, unique(map(e -> superedge(pg, e), es)))
end

Base.parent(se::SuperEdge) = getfield(se, :edge)
Graphs.src(se::SuperEdge) = SuperVertex(src(parent(se)))
Graphs.dst(se::SuperEdge) = SuperVertex(dst(parent(se)))
SuperEdge(p::Pair) = SuperEdge(NamedEdge(first(p) => last(p)))
SuperEdge(vsrc, vdst) = SuperEdge(vsrc => vdst)
Base.reverse(se::SuperEdge) = SuperEdge(reverse(parent(se)))

"""
    edges(pg::AbstractGraph, superedge::SuperEdge)
    edges(pg::AbstractGraph, superedges::Vector{SuperEdge})

Return the set of edges in the partitioned graph `pg` that correspond to the super edge `
superedge` or set of super edges `superedges`.
"""
function Graphs.edges(pg::AbstractGraph, superedge::SuperEdge)
    return partitioned_edges(pg)[parent(superedge)]
end
function Graphs.edges(pg::AbstractGraph, superedges::Vector{<:SuperEdge})
    return unique(reduce(vcat, [edges(pg, se) for se in superedges]))
end

function Graphs.has_edge(g::AbstractGraph, se::SuperEdge)
    return parent(se) in quotient_edges(g)
end

Graphs.ne(g::AbstractGraph, se::SuperEdge) = length(quotient_edges(g, se))

function Graphs.rem_edge!(g::AbstractGraph, se::SuperEdge)
    edges_to_remove = partitioned_edges(g, se)
    rem_edges!(g, edges_to_remove)
    return g
end
