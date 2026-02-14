using ..NamedGraphs.GraphsExtensions:
    GraphsExtensions, not_implemented, rem_edge, rem_edges!
using ..NamedGraphs: AbstractEdges, AbstractNamedEdge, AbstractNamedGraph, Edges,
    NamedGraphs, parent_graph_indices, to_edges
using Graphs: Graphs, AbstractEdge, AbstractGraph, dst, has_edge, ne, src

struct QuotientEdgeSlice{V, E, GI <: AbstractEdges{V, E}} <: AbstractEdges{V, E}
    inds::GI
end

NamedGraphs.parent_graph_indices(gs::QuotientEdgeSlice) = parent_graph_indices(gs.inds)

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
function has_quotientedge(g::AbstractGraph, se::QuotientEdge)
    return has_edge(quotient_graph(g), parent(se))
end

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

Base.getindex(qe::QuotientEdge, e) = QuotientEdgeEdge(qe.edge, e)
Base.getindex(qe::QuotientEdge, e::Pair) = QuotientEdgeEdge(qe.edge, NamedEdge(e))
Base.getindex(qe::QuotientEdge, e::Edges) = QuotientEdgeEdges(qe.edge, e.edges)

function Graphs.src(qee::QuotientEdgeEdge)
    return QuotientVertexVertex(src(qee.quotientedge), src(qee.edge))
end
function Graphs.dst(qee::QuotientEdgeEdge)
    return QuotientVertexVertex(dst(qee.quotientedge), dst(qee.edge))
end
function Base.reverse(se::QuotientEdgeEdge)
    return QuotientEdgeEdge(reverse(se.quotientedge), reverse(se.edge))
end

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

NamedGraphs.parent_graph_indices(qees::QuotientEdgeEdges) = qees.edges

Base.eltype(::QuotientEdgeEdges{V, E, QE}) where {V, E, QE} = QuotientEdgeEdge{V, E, QE}

function Base.iterate(qes::QuotientEdgeEdges, state...)
    return iterate(
        Iterators.map(e -> QuotientEdge(qes.quotientedge)[e], qes.edges),
        state...
    )
end

function Base.getindex(qes::QuotientEdgeEdges, i::Int)
    return QuotientEdgeEdge(qes.quotientedge, qes.edges[i])
end
function Base.getindex(qes::QuotientEdgeEdges, i)
    return QuotientEdgeEdges(qes.quotientedge, qes.edges[i])
end

# Represents multiple edges across multiple QuotientEdges
struct QuotientEdgesEdges{V, E, QE, Es <: AbstractVector{<:QuotientEdgeEdge}, QEs} <:
    AbstractEdges{V, E}
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

# Underscore function used to isolate implementation from interface function `to_graph_index`
function _to_graph_index(graph::AbstractGraph, qe::QuotientEdge)
    return QuotientEdgeEdges(qe.edge, edges(graph, qe))
end
function NamedGraphs.to_graph_index(graph::AbstractGraph, qe::QuotientEdge)
    return _to_graph_index(graph, qe)
end
function NamedGraphs.to_edges(graph::AbstractGraph, qe::QuotientEdge)
    return to_edges(graph, _to_graph_index(graph, qe))
end

function NamedGraphs.to_graph_index(graph::AbstractGraph, qee::QuotientEdgeEdge)
    if !has_quotientedge(graph, QuotientEdge(qee.quotientedge))
        throw(ArgumentError("Quotient edge $(qee.quotientedge) not in graph"))
    end
    return qee.edge
end
function NamedGraphs.to_edges(g::AbstractGraph, qee::QuotientEdgeEdge)
    return to_edges(g, QuotientEdgeEdges(qee.quotientedge, [to_graph_index(g, qee)]))
end

NamedGraphs.to_graph_index(::AbstractGraph, qes::QuotientEdges) = qes
function NamedGraphs.to_edges(g::AbstractGraph, qes::QuotientEdges)
    edges = mapreduce(vcat, qes) do qe
        return collect(to_edges(g, qe).inds)
    end
    return to_edges(g, QuotientEdgesEdges(qes, edges))
end

NamedGraphs.to_graph_index(::AbstractGraph, qees::QuotientEdgeEdges) = qees
NamedGraphs.to_edges(::AbstractGraph, qees::QuotientEdgeEdges) = QuotientEdgeSlice(qees)

NamedGraphs.to_graph_index(::AbstractGraph, qeses::QuotientEdgesEdges) = qeses
NamedGraphs.to_edges(::AbstractGraph, qeses::QuotientEdgesEdges) = QuotientEdgeSlice(qeses)

# This function preprocesses a vector of graph indices into an appropriate index object for
# canonization via `to_graph_index` and `to_edges`.
function graph_index_list_to_graph_index(g::AbstractGraph, qes::Vector{<:QuotientEdgeEdge})
    return Edges(map(qee -> to_graph_index(g, qee), qes))
end
function NamedGraphs.to_graph_index(g::AbstractGraph, qes::Vector{<:QuotientEdgeEdge})
    return to_graph_index(g, graph_index_list_to_graph_index(g, qes))
end
function NamedGraphs.to_edges(g::AbstractGraph, qes::Vector{<:QuotientEdgeEdge})
    return to_edges(g, graph_index_list_to_graph_index(g, qes))
end

# Conversions to `QuotientEdgesEdges`
function graph_index_list_to_graph_index(::AbstractGraph, qe::Vector{<:QuotientEdge})
    return QuotientEdges(map(e -> e.edge, qe))
end
function NamedGraphs.to_graph_index(g::AbstractGraph, qe::Vector{<:QuotientEdge})
    return to_graph_index(g, graph_index_list_to_graph_index(g, qe))
end
function NamedGraphs.to_edges(g::AbstractGraph, qe::Vector{<:QuotientEdge})
    return to_edges(g, graph_index_list_to_graph_index(g, qe))
end

function graph_index_list_to_graph_index(::AbstractGraph, qes::Vector{<:QuotientEdgeEdges})
    return QuotientEdgesEdges(qes, mapreduce(collect, vcat, qes))
end
function NamedGraphs.to_graph_index(g::AbstractGraph, qes::Vector{<:QuotientEdgeEdges})
    return to_graph_index(g, graph_index_list_to_graph_index(g, qes))
end
function NamedGraphs.to_edges(g::AbstractGraph, qes::Vector{<:QuotientEdgeEdges})
    return to_edges(g, graph_index_list_to_graph_index(g, qes))
end
