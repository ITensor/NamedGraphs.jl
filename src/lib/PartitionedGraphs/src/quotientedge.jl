using Graphs: AbstractGraph, Graphs, AbstractEdge, dst, src, ne, has_edge
using ..NamedGraphs:
    NamedGraphs,
    AbstractNamedGraph,
    AbstractNamedEdge,
    AbstractEdges,
    Edges,
    parent_graph_indices
using ..NamedGraphs.GraphsExtensions: GraphsExtensions, not_implemented, rem_edges!, rem_edge

"""
    QuotientEdge(e)

Represents a super-edge in a partitioned graph corresponding to the set of edges
in between partitions `src(e)` and `dst(e)`.
"""
struct QuotientEdge{V, E <: AbstractEdge{V}} <: AbstractNamedEdge{V}
    edge::E
end

QuotientEdge(p::Pair) = QuotientEdge(NamedEdge(first(p) => last(p)))
QuotientEdge(vsrc, vdst) = QuotientEdge(vsrc => vdst)

Base.parent(se::QuotientEdge) = getfield(se, :edge)
Graphs.src(se::QuotientEdge) = QuotientVertex(src(parent(se)))
Graphs.dst(se::QuotientEdge) = QuotientVertex(dst(parent(se)))
Base.reverse(se::QuotientEdge) = QuotientEdge(reverse(parent(se)))

quotient_index(edge::AbstractEdge) = QuotientEdge(edge)

"""
    quotientedge(g::AbstractGraph{V}, edge) -> QuotientEdge{V}

Return the the quotient edge corresponding to `edge` of the graph `g`. Note,
the returned quotient edge may be a self-loop.

See also: `quotientedges`, `quotienttvertex`.
"""
quotientedge(g::AbstractGraph, edge::Pair) = quotientedge(g, edgetype(g)(edge))
function quotientedge(g::AbstractGraph, edge::AbstractEdge)
    if !has_edge(g, edge)
        throw(ArgumentError("Graph does not have an edge $edge"))
    end
    qv_src = parent(quotientvertex(g, src(edge)))
    qv_dst = parent(quotientvertex(g, dst(edge)))
    return QuotientEdge(quotient_graph_edgetype(g)(qv_src => qv_dst))
end

struct QuotientEdges{V, E, Es} <: AbstractEdges{V, E}
    edges::Es
    function QuotientEdges{V, E}(edges::Es) where {V, E, Es}
        @assert E <: eltype(Es)
        return new{V, E, Es}(edges)
    end
end

Base.eltype(::QuotientEdges{V, E}) where {V, E} = QuotientEdge{V, E}

function QuotientEdges(edges::Es) where {Es}
    E = eltype(Es)
    return QuotientEdges{vertextype(E), E}(edges)
end

QuotientEdges(g::AbstractGraph) = QuotientEdges(edges(quotient_graph(g)))

NamedGraphs.parent_graph_indices(qvs::QuotientEdges) = getfield(qvs, :edges)

function Base.iterate(qvs::QuotientEdges, state = nothing)
    if isnothing(state)
        out = iterate(getfield(qvs, :edges))
    else
        out = iterate(getfield(qvs, :edges), state)
    end
    if isnothing(out)
        return nothing
    else
        (v, s) = out
        return (QuotientEdge(v), s)
    end
end

"""
    quotientedges(g::AbstractGraph, es = edges(pg)) -> QuotientEdges

Return all unique quotient edges corresponding to the set of edges `es` of the graph `g`.
"""
quotientedges(g::AbstractGraph) = QuotientEdges(g)
function quotientedges(pg::AbstractGraph, es)
    edges = filter!(!is_self_loop, unique(map(e -> parent(quotientedge(pg, e)), es)))
    return QuotientEdges(edges)
end

"""
    edges(g::AbstractGraph, quotientedge::QuotientEdge)
    edges(g::AbstractGraph, quotientedges::QuotientEdges)

Return the set of edges in the graph `g` that correspond to a single quotient edge or
a list of quotient edges.
"""
function Graphs.edges(pg::AbstractGraph, quotientedge::QuotientEdge)

    pes = partitioned_edges(pg)
    defval = edgetype(pg)[]

    rv = get(pes, parent(quotientedge), defval)
    if !is_directed(quotient_graph_type(pg)) && isempty(rv)
        append!(rv, get(pes, reverse(parent(quotientedge)), defval))
    end

    isempty(rv) && throw(ArgumentError("Quotient edge $quotientedge not in graph"))

    return rv
end
function Graphs.edges(pg::AbstractGraph, quotientedges::QuotientEdges)
    return unique(reduce(vcat, [edges(pg, qe) for qe in quotientedges]))
end

"""
    has_quotientedge(g::AbstractGraph, qe::QuotientEdge) -> Bool

Returns true if the quotient edge `qe` exists in the quotient graph of `g`.
"""
has_quotientedge(g::AbstractGraph, se::QuotientEdge) = has_edge(quotient_graph(g), parent(se))

"""
    ne(g::AbstractGraph, qe::QuotientEdge) -> Int

Returns the number of edges in `g` that correspond to the quotient edge `qe`.

See also: `nv`.
"""
Graphs.ne(g::AbstractGraph, se::QuotientEdge) = length(edges(g, se))


"""
    rem_edges!(g::AbstractGraph, qe::QuotientEdge) -> Int

Remove, in place, all the edges of `g` that correspond to the quotient edge `qe`.
"""
function GraphsExtensions.rem_edges!(g::AbstractGraph, sv::QuotientEdge)
    return rem_edges!(g, edges(g, sv))
end

rem_quotientedge!(g::AbstractGraph, sv::QuotientEdge) = rem_edges!(g, sv)

struct QuotientSubEdges{V, E, QE, Es} <: AbstractEdges{V, E}
    quotients::QE
    edges::Es
    function QuotientSubEdges(qe::QE, edges::Es) where {QE, Es}
        E = eltype(Es)
        V = vertextype(E)
        return new{V, E, QE, Es}(qe, edges)
    end
end

quotients(qes::QuotientSubEdges) = getfield(qes, :quotients)
departition(qes::QuotientSubEdges) = getfield(qes, :edges)

NamedGraphs.parent_graph_indices(qes::QuotientSubEdges) = departition(qes)

# A single QuotientEdge should index like a list of edges
function NamedGraphs.to_graph_indexing(g::AbstractGraph, qe::QuotientEdge)
    return QuotientSubEdges(qe, edges(g, qe))
end
# QuotientEdges should index like a list of quotient edges
NamedGraphs.to_graph_indexing(::AbstractGraph, qv::QuotientEdges) = qv

const QuotientEdgeSubEdges{V, E, QE <: QuotientEdge, Es} = QuotientSubEdges{V, E, QE, Es}
const QuotientEdgesSubEdges{V, E, QE <: QuotientEdges, Es} = QuotientSubEdges{V, E, QE, Es}

quotient_index(subedges::QuotientEdgeSubEdges) = quotients(subedges)
quotient_indices(subedges::QuotientEdgesSubEdges) = quotients(subedges)
