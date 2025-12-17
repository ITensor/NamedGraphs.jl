using Graphs: AbstractGraph, Graphs, nv, induced_subgraph
using ..NamedGraphs: NamedGraphs, AbstractNamedGraph, AbstractVertices, Vertices, Edges
using ..NamedGraphs.GraphsExtensions: GraphsExtensions, rem_vertices!, subgraph
using ..NamedGraphs.OrderedDictionaries: OrderedIndices


"""
    QuotientVertex(v)

Represents a super-vertex in a partitioned graph corresponding to the set of vertices
in partition `v`.
"""
struct QuotientVertex{V}
    vertex::V
end

Base.parent(sv::QuotientVertex) = getfield(sv, :vertex)

# Overload this for fast inverse mapping for vertices and edges
function quotientvertex(g, vertex)
    pvs = partitioned_vertices(g)
    rv = findfirst(pv -> vertex ∈ pv, pvs)
    if isnothing(rv)
        error("Vertex $vertex not found in any partition.")
    end
    return QuotientVertex(rv)
end

"""
    quotientvertices(g::AbstractGraph, vs = vertices(pg))

Return all unique quotient vertices corresponding to the set vertices `vs` of the graph `pg`.
"""
quotientvertices(g) = Iterators.map(QuotientVertex, keys(partitioned_vertices(g)))
quotientvertices(g::AbstractGraph, vs) = unique(map(v -> quotientvertex(g, v), vs))

"""
    vertices(g::AbstractGraph, quotientvertex::QuotientVertex)
    vertices(g::AbstractGraph, quotientvertices::Vector{QuotientVertex})

Return the set of vertices in the graph `g` associated with the quotient vertex
`quotientvertex` or set of quotient vertices `quotientvertices`.
"""
function Graphs.vertices(g::AbstractGraph, quotientvertex::QuotientVertex)
    qv = parent(quotientvertex)

    pvs = partitioned_vertices(g)
    haskey(pvs, qv) || throw(ArgumentError("Quotient vertex $quotientvertex not in graph"))

    return pvs[qv]
end
function Graphs.vertices(g::AbstractGraph, quotientvertices::Vector{<:QuotientVertex})
    return unique(mapreduce(sv -> vertices(g, sv), vcat, quotientvertices))
end

function has_quotientvertex(g::AbstractGraph, quotientvertex::QuotientVertex)
    qg = quotient_graph_type(g)(parent.(quotientvertices(g)))
    return has_vertex(qg, parent(quotientvertex))
end

Graphs.nv(g::AbstractGraph, sv::QuotientVertex) = length(vertices(g, sv))

function GraphsExtensions.rem_vertices!(g::AbstractGraph, sv::QuotientVertex)
    return rem_vertices!(g, vertices(g, sv))
end
rem_quotientvertex!(pg::AbstractGraph, sv::QuotientVertex) = rem_vertices!(pg, sv)

# Represents a set of subvertices corresponding to a set of quotient vertices.
struct SubVertices{QV, V, Vs <: AbstractVector{V}} <: AbstractVector{V}
    quotientvertices::QV
    vertices::Vs
end
Base.size(v::SubVertices) = size(v.vertices)
Base.getindex(v::SubVertices, I...) = v.vertices[I...]

function NamedGraphs.to_vertices(g::AbstractGraph, qv::QuotientVertex)
    return SubVertices(qv, vertices(g, qv))
end
function NamedGraphs.to_vertices(g::AbstractGraph, qv::AbstractVector{<:QuotientVertex})
    return SubVertices(qv, vertices(g, qv))
end

# Special case so that `subgraph(g, QuotientVertex(v))` returns an unpartitioned graph.
function NamedGraphs.induced_subgraph_from_vertices(
        g::AbstractGraph, subvertices::SubVertices{<:QuotientVertex}
    )
    sg, vs = NamedGraphs.induced_subgraph_from_vertices(g, subvertices.vertices)
    return unpartitioned_graph(sg), vs
end

struct QuotientVertices{V, Vs} <: AbstractVertices{V}
    vertices::Vs
    QuotientVertices(vertices::Vs) where {Vs} = new{eltype(Vs), Vs}(vertices)
end
NamedGraphs.parent_graph_indices(qvs::QuotientVertices) = getfield(qvs, :vertices)

struct QuotientVertexVertices{V, QV, Vs} <: AbstractVertices{V}
    quotientvertex::QuotientVertex{QV}
    vertices::Vs
    function QuotientVertexVertices(qv::QuotientVertex{QV}, vertices::Vs) where {QV, Vs}
        V = eltype(vertices)
        return new{V, QV, Vs}(qv, vertices)
    end
end

quotient_index(qvs::QuotientVertexVertices) = getfield(qvs, :quotientvertex)
departition(qvs::QuotientVertexVertices) = getfield(qvs, :vertices)

NamedGraphs.parent_graph_indices(qvs::QuotientVertexVertices) = departition(qvs)

function NamedGraphs.to_graph_indexing(g, qv::QuotientVertex)
    return QuotientVertexVertices(qv, vertices(g, qv))
end
