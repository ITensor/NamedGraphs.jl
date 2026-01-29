using Graphs: AbstractGraph, Graphs, nv, induced_subgraph
using ..NamedGraphs:
    NamedGraphs,
    AbstractNamedGraph,
    AbstractVertices,
    Vertices,
    Edges,
    to_vertices,
    to_graph_index,
    parent_graph_indices
using ..NamedGraphs.GraphsExtensions: GraphsExtensions, rem_vertices!, subgraph
using ..NamedGraphs.OrderedDictionaries: OrderedIndices

struct QuotientVertexSlice{V, GI <: AbstractVertices{V}} <: AbstractVertices{V}
    inds::GI
end

NamedGraphs.parent_graph_indices(gs::QuotientVertexSlice) = parent_graph_indices(gs.inds)

"""
    QuotientVertex(v)

Represents a super-vertex in a partitioned graph corresponding to the set of vertices
in partition `v`.
"""
struct QuotientVertex{V}
    vertex::V
end

Base.parent(sv::QuotientVertex) = getfield(sv, :vertex)

to_quotient_index(vertex) = QuotientVertex(vertex)

# Overload this for fast inverse mapping for vertices and edges
function quotientvertex(g, vertex)
    pvs = partitioned_vertices(g)
    rv = findfirst(pv -> vertex ∈ pv, pvs)
    if isnothing(rv)
        error("Vertex $vertex not found in any partition.")
    end
    return QuotientVertex(rv)
end

# Represents a set of quotient vertices.
struct QuotientVertices{V, Vs} <: AbstractVertices{V}
    vertices::Vs
    function QuotientVertices(vertices::Vs) where {Vs}
        return new{eltype(Vs), Vs}(vertices)
    end
end

to_quotient_index(vertices::Vertices) = QuotientVertices(vertices.vertices)

Base.eltype(::QuotientVertices{V}) where {V} = QuotientVertex{V}

QuotientVertices(g::AbstractGraph) = QuotientVertices(keys(partitioned_vertices(g)))

NamedGraphs.parent_graph_indices(qvs::QuotientVertices) = qvs.vertices

function Base.iterate(qvs::QuotientVertices, state...)
    return iterate(Iterators.map(QuotientVertex, qvs.vertices), state...)
end

Base.getindex(qvs::QuotientVertices, i::Int) = QuotientVertex(qvs.vertices[i])
Base.getindex(qvs::QuotientVertices, i) = QuotientVertices(qvs.vertices[i])

"""
    quotientvertices(g::AbstractGraph, vs = vertices(pg))

Return an iterator over unique quotient vertices corresponding to the set vertices `vs`
of the graph `pg`.
"""
quotientvertices(g) = QuotientVertices(g)
quotientvertices(g::AbstractGraph, vs) = QuotientVertices(unique(map(v -> parent(quotientvertex(g, v)), vs)))

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
function Graphs.vertices(g::AbstractGraph, quotientvertices::QuotientVertices)
    return unique(mapreduce(qv -> vertices(g, qv), vcat, quotientvertices))
end

function has_quotientvertex(g::AbstractGraph, quotientvertex::QuotientVertex)
    return haskey(partitioned_vertices(g), parent(quotientvertex))
end

Graphs.nv(g::AbstractGraph, sv::QuotientVertex) = length(vertices(g, sv))

function GraphsExtensions.rem_vertices!(g::AbstractGraph, sv::QuotientVertex)
    return rem_vertices!(g, vertices(g, sv))
end
rem_quotientvertex!(pg::AbstractGraph, sv::QuotientVertex) = rem_vertices!(pg, sv)

# Represents a single vertex in a QuotientVertex
struct QuotientVertexVertex{V, QV}
    quotientvertex::QV
    vertex::V
end

Base.getindex(qv::QuotientVertex, v) = QuotientVertexVertex(qv.vertex, v)
Base.getindex(qv::QuotientVertex, v::Vertices) = QuotientVertexVertices(qv.vertex, v.vertices)

GraphsExtensions.vertextype(::Type{<:QuotientVertexVertex{V}}) where {V} = V
GraphsExtensions.vertextype(::Type{<:QuotientVertexVertex}) = Any

quotient_vertextype(::Type{<:QuotientVertexVertex{V, QV}}) where {V, QV} = QV

# Represents multiple vertices in a single QuotientVertex
struct QuotientVertexVertices{V, QV, Vs} <: AbstractVertices{V}
    quotientvertex::QV
    vertices::Vs
    function QuotientVertexVertices(qv::QV, vertices::Vs) where {QV, Vs}
        V = eltype(vertices)
        return new{V, QV, Vs}(qv, vertices)
    end
end

NamedGraphs.parent_graph_indices(qvs::QuotientVertexVertices) = qvs.vertices

Base.eltype(::QuotientVertexVertices{V, QV}) where {V, QV} = QuotientVertexVertex{V, QV}

function Base.iterate(qvs::QuotientVertexVertices, state...)
    return iterate(Iterators.map(v -> QuotientVertex(qvs.quotientvertex)[v], qvs.vertices), state...)
end

# Linear indexing with a scalar returns a `QuotientVertexVertex`
function Base.getindex(qvs::QuotientVertexVertices, i::Int)
    return QuotientVertexVertex(qvs.quotientvertex, qvs.vertices[i])
end

# Linear indexing with something that isnt a scalar assumes the result is a collection of vertices
# and thus returns a `QuotientVertexVertices`
function Base.getindex(qvs::QuotientVertexVertices, i)
    return QuotientVertexVertices(qvs.quotientvertex, qvs.vertices[i])
end

# Represents multiple vertices across multiple QuotientVertices
struct QuotientVerticesVertices{V, QV, Vs <: AbstractVector{<:QuotientVertexVertex}, QVs} <: AbstractVertices{V}
    quotientvertices::QVs
    vertices::Vs
    function QuotientVerticesVertices(qvs::QVs, vertices::Vs) where {QVs, Vs}
        V = vertextype(eltype(Vs))
        QV = quotient_vertextype(eltype(Vs))
        return new{V, QV, Vs, QVs}(qvs, vertices)
    end
end

function NamedGraphs.parent_graph_indices(qvs::QuotientVerticesVertices)
    return map(qvv -> qvv.vertex, qvs.vertices)
end

Base.eltype(::QuotientVerticesVertices{V, QV}) where {V, QV} = QuotientVertexVertex{V, QV}

# `qvs.vertices` is already a collection of `QuotientVertexVertex` objects, so can just forward
# this directly.
Base.getindex(qvs::QuotientVerticesVertices, i) = qvs.vertices[i]

Base.iterate(qvsvs::QuotientVerticesVertices, state...) = iterate(qvsvs.vertices, state...)

function _to_graph_index(graph::AbstractGraph, qv::QuotientVertex)
    return QuotientVertexVertices(qv.vertex, vertices(graph, qv))
end
function NamedGraphs.to_graph_index(graph::AbstractGraph, qv::QuotientVertex)
    return _to_graph_index(graph, qv)
end
function NamedGraphs.to_vertices(graph::AbstractGraph, qv::QuotientVertex)
    return to_vertices(graph, _to_graph_index(graph, qv))
end

function NamedGraphs.to_graph_index(g::AbstractGraph, qvv::QuotientVertexVertex)
    if !has_quotientvertex(g, QuotientVertex(qvv.quotientvertex))
        throw(ArgumentError("Quotient vertex $(qvv.quotientvertex) not in graph"))
    end
    return qvv.vertex
end
function NamedGraphs.to_vertices(g::AbstractGraph, qvv::QuotientVertexVertex)
    return to_vertices(g, QuotientVertexVertices(qvv.quotientvertex, [to_graph_index(g, qvv)]))
end

NamedGraphs.to_graph_index(::AbstractGraph, qvs::QuotientVertices) = qvs
function NamedGraphs.to_vertices(g::AbstractGraph, qvs::QuotientVertices)
    vertices = mapreduce(vcat, qvs) do qv
        return collect(to_vertices(g, qv).inds)
    end
    return to_vertices(g, QuotientVerticesVertices(qvs, vertices))
end

NamedGraphs.to_graph_index(::AbstractGraph, qvvs::QuotientVertexVertices) = qvvs
NamedGraphs.to_vertices(::AbstractGraph, qvvs::QuotientVertexVertices) = QuotientVertexSlice(qvvs)

NamedGraphs.to_graph_index(::AbstractGraph, qvsvs::QuotientVerticesVertices) = qvsvs
NamedGraphs.to_vertices(::AbstractGraph, qvsvs::QuotientVerticesVertices) = QuotientVertexSlice(qvsvs)

# This function preprocesses a vector of graph indices into an appropriate index object for
# canonization via `to_graph_index` and `to_vertices`.
function graph_index_list_to_graph_index(g::AbstractGraph, qvs::Vector{<:QuotientVertexVertex})
    return Vertices(map(qvv -> to_graph_index(g, qvv), qvs))
end
function NamedGraphs.to_graph_index(g::AbstractGraph, qvs::Vector{<:QuotientVertexVertex})
    return to_graph_index(g, graph_index_list_to_graph_index(g, qvs))
end
function NamedGraphs.to_vertices(g::AbstractGraph, qvs::Vector{<:QuotientVertexVertex})
    return to_vertices(g, graph_index_list_to_graph_index(g, qvs))
end

# Conversions to `QuotientVerticesVertices`
function graph_index_list_to_graph_index(::AbstractGraph, qv::Vector{<:QuotientVertex})
    return QuotientVertices(map(v -> v.vertex, qv))
end
function NamedGraphs.to_graph_index(g::AbstractGraph, qv::Vector{<:QuotientVertex})
    return to_graph_index(g, graph_index_list_to_graph_index(g, qv))
end
function NamedGraphs.to_vertices(g::AbstractGraph, qv::Vector{<:QuotientVertex})
    return to_vertices(g, graph_index_list_to_graph_index(g, qv))
end

function graph_index_list_to_graph_index(::AbstractGraph, qvs::Vector{<:QuotientVertexVertices})
    return QuotientVerticesVertices(qvs, mapreduce(collect, vcat, qvs))
end
function NamedGraphs.to_graph_index(g::AbstractGraph, qvs::Vector{<:QuotientVertexVertices})
    return to_graph_index(g, graph_index_list_to_graph_index(g, qvs))
end
function NamedGraphs.to_vertices(g::AbstractGraph, qvs::Vector{<:QuotientVertexVertices})
    return to_vertices(g, graph_index_list_to_graph_index(g, qvs))
end
