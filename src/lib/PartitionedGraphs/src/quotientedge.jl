using Graphs: AbstractGraph, Graphs, AbstractEdge, dst, src, ne, has_edge
using ..NamedGraphs: AbstractNamedEdge
using ..NamedGraphs.GraphsExtensions: GraphsExtensions, not_implemented, rem_edges!, rem_edge

struct QuotientEdge{V, E <: AbstractEdge{V}} <: AbstractNamedEdge{V}
    edge::E
end

quotientedge(pg::AbstractGraph, p::Pair) = quotientedge(pg, edgetype(pg)(p))

"""
    quotientedges(pg::AbstractPartitionedGraph, es = edges(pg))

Return all unique quotient edges corresponding to the set edges `es` of the graph `pg`.
"""
quotientedges(g::AbstractGraph) = QuotientEdge.(edges(quotient_graph(g)))
function quotientedges(pg::AbstractGraph, es)
    return filter!(!is_self_loop, unique(map(e -> quotientedge(pg, e), es)))
end

Base.parent(se::QuotientEdge) = getfield(se, :edge)
Graphs.src(se::QuotientEdge) = QuotientVertex(src(parent(se)))
Graphs.dst(se::QuotientEdge) = QuotientVertex(dst(parent(se)))
QuotientEdge(p::Pair) = QuotientEdge(NamedEdge(first(p) => last(p)))
QuotientEdge(vsrc, vdst) = QuotientEdge(vsrc => vdst)
Base.reverse(se::QuotientEdge) = QuotientEdge(reverse(parent(se)))

"""
    edges(pg::AbstractGraph, quotientedge::QuotientEdge)
    edges(pg::AbstractGraph, quotientedges::Vector{QuotientEdge})

Return the set of edges in the partitioned graph `pg` that correspond to the quotient edge `
quotientedge` or set of quotient edges `quotientedges`.
"""
function Graphs.edges(pg::AbstractGraph, quotientedge::QuotientEdge)

    pes = partitioned_edges(pg)
    defval = edgetype(pg)[]

    rv = get(pes, parent(quotientedge), defval)
    if !is_directed(quotient_graph_type(pg)) && isempty(rv)
        append!(rv, get(pes, reverse(parent(quotientedge)), defval))
    end

    isempty(rv) && throw(ArgumentError("Super edge $quotientedge not in graph"))

    return rv
end
function Graphs.edges(pg::AbstractGraph, quotientedges::Vector{<:QuotientEdge})
    return unique(reduce(vcat, [edges(pg, se) for se in quotientedges]))
end

has_quotientedge(g::AbstractGraph, se::QuotientEdge) = has_edge(quotient_graph(g), parent(se))

Graphs.ne(g::AbstractGraph, se::QuotientEdge) = length(edges(g, se))

function GraphsExtensions.rem_edges!(g::AbstractGraph, sv::QuotientEdge)
    rv = rem_edges!(g, edges(g, sv))
    return rv
end
rem_quotientedge!(pg::AbstractGraph, sv::QuotientEdge) = rem_edges!(pg, sv)
