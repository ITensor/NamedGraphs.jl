using Graphs: AbstractGraph, Graphs, AbstractEdge, dst, src, ne, has_edge
using ..NamedGraphs: AbstractNamedEdge
using ..NamedGraphs.GraphsExtensions: GraphsExtensions, not_implemented, rem_edges!, rem_edge

struct SuperEdge{V, E <: AbstractEdge{V}} <: AbstractNamedEdge{V}
    edge::E
end

superedge(pg::AbstractGraph, edge::AbstractEdge) = SuperEdge(quotient_edge(pg, edge))
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

    pes = partitioned_edges(pg)
    defval = edgetype(pg)[]

    rv = get(pes, parent(superedge), defval)
    if !is_directed(quotient_graph_type(pg)) && isempty(rv)
        append!(rv, get(pes, reverse(parent(superedge)), defval))
    end

    isempty(rv) && throw(ArgumentError("Super edge $superedge not in graph"))

    return rv
end
function Graphs.edges(pg::AbstractGraph, superedges::Vector{<:SuperEdge})
    return unique(reduce(vcat, [edges(pg, se) for se in superedges]))
end

has_superedge(g::AbstractGraph, se::SuperEdge) = has_edge(quotient_graph(g), parent(se))

Graphs.ne(g::AbstractGraph, se::SuperEdge) = length(edges(g, se))

function GraphsExtensions.rem_edges!(g::AbstractGraph, sv::SuperEdge)
    rv = rem_edges!(g, edges(g, sv))
    return rv
end
rem_superedge!(pg::AbstractGraph, sv::SuperEdge) = rem_edges!(pg, sv)
