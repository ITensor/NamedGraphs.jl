using Graphs: AbstractGraph, Graphs, AbstractEdge, dst, src, ne, has_edge
using ..NamedGraphs:
    NamedGraphs,
    AbstractNamedGraph,
    AbstractNamedEdge,
    AbstractEdges,
    Edges,
    EdgeSlice,
    to_edges,
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

to_quotient_index(edge::AbstractEdge) = QuotientEdge(edge)
quotient_index(qe) = qe

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
    function QuotientEdges(edges::Es) where {Es}
        E = eltype(edges)
        V = vertextype(E)
        return new{V, E, Es}(edges)
    end
end

to_quotient_index(edges::Edges) = QuotientEdges(edges.edges)
to_quotient_index(edges::QuotientEdges) = QuotientEdges(collect(edges.edges))

Base.eltype(::QuotientEdges{V, E}) where {V, E} = QuotientEdge{V, E}

QuotientEdges(g::AbstractGraph) = QuotientEdges(edges(quotient_graph(g)))

NamedGraphs.parent_graph_indices(qes::QuotientEdges) = qes.edges

function Base.iterate(qes::QuotientEdges, state...)
    return iterate(Iterators.map(QuotientEdge, qes.edges), state...)
end

Base.getindex(qes::QuotientEdges, i::Int) = QuotientEdge(qes.edges[i])
Base.getindex(qes::QuotientEdges, i) = QuotientEdges(qes.edges[i])

"""
    quotientedges(g::AbstractGraph, es = edges(pg)) -> QuotientEdges

Return an iterator over all unique quotient edges corresponding to the set of edges `es` of
the graph `g`.
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

# Represents a single edge in a QuotientEdge
struct QuotientEdgeEdge{V, E <: AbstractNamedEdge{V}, QE} <: AbstractNamedEdge{V}
    quotientedge::QE
    edge::E
end

quotient_index(qee::QuotientEdgeEdge) = QuotientEdge(qee.quotientedge)

Base.getindex(qe::QuotientEdge, e) = QuotientEdgeEdge(qe.edge, e)
Base.getindex(qe::QuotientEdge, e::Pair) = QuotientEdgeEdge(qe.edge, NamedEdge(e))
Base.getindex(qe::QuotientEdge, e::Edges) = QuotientEdgeEdges(qe.edge, e.edges)

Graphs.src(qee::QuotientEdgeEdge) = QuotientVertexVertex(src(qee.quotientedge), src(qee.edge))
Graphs.dst(qee::QuotientEdgeEdge) = QuotientVertexVertex(dst(qee.quotientedge), dst(qee.edge))
Base.reverse(se::QuotientEdgeEdge) = QuotientEdgeEdge(reverse(se.quotientedge), reverse(se.edge))

Graphs.edgetype(::Type{<:QuotientEdgeEdge{V, E}}) where {V, E} = E
Graphs.edgetype(::Type{<:QuotientEdgeEdge{V}}) where {V} = AbstractNamedEdge{V}
Graphs.edgetype(::Type{<:QuotientEdgeEdge}) = AbstractNamedEdge

GraphsExtensions.vertextype(::Type{<:QuotientEdgeEdge{V, E}}) where {V, E} = V

quotient_edgetype(::Type{<:QuotientEdgeEdge{V, E, QE}}) where {V, E, QE} = QE

struct QuotientEdgeEdges{V, E, QE, Es} <: AbstractEdges{V, E}
    quotientedge::QE
    edges::Es
    function QuotientEdgeEdges(qe::QE, edges::Es) where {QE, Es}
        E = eltype(Es)
        V = vertextype(E)
        return new{V, E, QE, Es}(qe, edges)
    end
end

quotient_index(qee::QuotientEdgeEdges) = QuotientEdge(qee.quotientedge)

NamedGraphs.parent_graph_indices(qees::QuotientEdgeEdges) = qees.edges

Base.eltype(::QuotientEdgeEdges{V, E, QE}) where {V, E, QE} = QuotientEdgeEdge{V, E, QE}

function Base.iterate(qes::QuotientEdgeEdges, state...)
    return iterate(Iterators.map(e -> QuotientEdge(qes.quotientedge)[e], qes.edges), state...)
end

function Base.getindex(qes::QuotientEdgeEdges, i::Int)
    return QuotientEdgeEdge(qes.quotientedge, qes.edges[i])
end
function Base.getindex(qes::QuotientEdgeEdges, i)
    return QuotientEdgeEdges(qes.quotientedge, qes.edges[i])
end

# Represents multiple edges across multiple QuotientEdges
struct QuotientEdgesEdges{V, E, QE, Es <: AbstractVector{<:QuotientEdgeEdge}, QEs} <: AbstractEdges{V, E}
    quotientedges::QEs
    edges::Es
    function QuotientEdgesEdges(qes::QEs, edges::Es) where {QEs, Es}
        E = edgetype(eltype(Es))
        V = vertextype(E)
        QE = quotient_edgetype(eltype(Es))
        return new{V, E, QE, Es, QEs}(qes, edges)
    end
end

function NamedGraphs.parent_graph_indices(qes::QuotientEdgesEdges)
    return map(qee -> qee.edge, qes.edges)
end

Base.eltype(::QuotientEdgesEdges{E, QE}) where {E, QE} = QuotientEdgeEdge{E, QE}

# `qvs.edges` is already a collection of `QuotientEdgeEdge` objects, so can just forward
# this directly.
Base.getindex(qes::QuotientEdgesEdges, i) = qes.edges[i]

Base.iterate(qeses::QuotientEdgesEdges, state...) = iterate(qeses.edges, state...)

NamedGraphs.to_graph_index(::AbstractGraph, qe::QuotientEdge) = qe
function NamedGraphs.to_graph_indices(graph::AbstractGraph, qe::QuotientEdge)
    return QuotientEdgeEdges(qe.edge, edges(graph, qe))
end
function NamedGraphs.to_edges(graph::AbstractGraph, qe::QuotientEdge)
    return EdgeSlice(to_graph_indices(graph, qe))
end

function NamedGraphs.to_graph_index(graph::AbstractGraph, qee::QuotientEdgeEdge)
    if has_quotientedge(graph, quotient_index(qee))
        return qee.edge
    else
        throw(ArgumentError("Quotient edge $(qee.quotientedge) not in graph"))
    end
end
NamedGraphs.to_graph_indices(g::AbstractGraph, qee::QuotientEdgeEdge) = to_edges(g, qee)
function NamedGraphs.to_edges(g::AbstractGraph, qee::QuotientEdgeEdge)
    return QuotientEdgeEdges(qee.quotientedge, [to_graph_index(g, qee)])
end


NamedGraphs.to_graph_index(::AbstractGraph, qes::QuotientEdges) = qes
NamedGraphs.to_graph_indices(::AbstractGraph, qes::QuotientEdges) = qes
function NamedGraphs.to_edges(g::AbstractGraph, qes::QuotientEdges)
    edges = mapreduce(
        qe -> collect(to_graph_indices(g, qe)),
        vcat,
        qes,
    )
    return QuotientEdgesEdges(qes, edges)
end


function NamedGraphs.to_graph_indices(::AbstractGraph, qes::AbstractVector{<:QuotientEdge})
    return QuotientEdges(map(qes -> qes.edge, qes))
end

function NamedGraphs.to_graph_index(g::AbstractGraph, qes::Vector{<:QuotientEdgeEdge})
    return to_graph_indices(g, qes)
end
function NamedGraphs.to_graph_indices(g::AbstractGraph, qes::Vector{<:QuotientEdgeEdge})
    return to_edges(g, qes)
end
function NamedGraphs.to_edges(g::AbstractGraph, qes::Vector{<:QuotientEdgeEdge})
    return Edges(map(qee -> to_graph_index(g, qee), qes))
end

NamedGraphs.to_graph_indices(::AbstractGraph, qe::QuotientEdgeEdges) = to_edges(qe)
NamedGraphs.to_edges(::AbstractGraph, qe::QuotientEdgeEdges) = EdgeSlice(qe)

# Coneersions to `QuotientEdgesEdges`
NamedGraphs.to_graph_index(g::AbstractGraph, qe::Vector{<:QuotientEdge}) = to_graph_indices(g, qe)
function NamedGraphs.to_graph_indices(::AbstractGraph, qe::Vector{<:QuotientEdge})
    return QuotientEdges(map(e -> e.edge, qe))
end
function NamedGraphs.to_edges(g::AbstractGraph, qe::Vector{<:QuotientEdge})
    return to_edges(g, to_graph_indices(g, qe))
end

NamedGraphs.to_graph_index(g::AbstractGraph, qe::Vector{<:QuotientEdgeEdges}) = to_graph_indices(g, qe)
function NamedGraphs.to_graph_indices(g::AbstractGraph, qe::Vector{<:QuotientEdgeEdges})
    return to_edges(g, qe)
end
function NamedGraphs.to_edges(::AbstractGraph, qes::Vector{<:QuotientEdgeEdges})
    return QuotientEdgesEdges(qes, mapreduce(collect, ecat, qes))
end
