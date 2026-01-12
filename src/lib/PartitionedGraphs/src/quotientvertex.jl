using Graphs: AbstractGraph, Graphs, nv, induced_subgraph
using ..NamedGraphs: NamedGraphs, AbstractNamedGraph, AbstractVertices, Vertices, Edges, to_vertices
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

# QuotientVertices and should index like a list of quotient vertices
NamedGraphs.to_graph_index(::AbstractGraph, qv::QuotientVertices) = qv

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

function NamedGraphs.to_vertices(g, qvv::QuotientVertexVertex)
    return QuotientVertex(qvv.quotientvertex)[Vertices([qvv.vertex])]
end

# Represents multiple vertices in a QuotientVertex
struct QuotientVertexVertices{V, QV, Vs} <: AbstractVertices{V}
    quotientvertex::QV
    vertices::Vs
    function QuotientVertexVertices(qv::QV, vertices::Vs) where {QV, Vs}
        V = eltype(vertices)
        return new{V, QV, Vs}(qv, vertices)
    end
end

Base.eltype(::QuotientVertexVertices{V, QV}) where {V, QV} = QuotientVertexVertex{V, QV}

NamedGraphs.parent_graph_indices(qvs::QuotientVertexVertices) = qvs.vertices

function Base.iterate(qvs::QuotientVertexVertices, state...)
    return iterate(Iterators.map(v -> QuotientVertex(qvs.quotientvertex)[v], qvs.vertices), state...)
end

function Base.getindex(qvs::QuotientVertexVertices, i::Int)
    return QuotientVertex(qvs.quotientvertex)[qvs.vertices[i]]
end
function Base.getindex(qvs::QuotientVertexVertices, i)
    return QuotientVertex(qvs.quotientvertex)[Vertices(qvs.vertices[i])]
end

# A single QuotientVertex and should index like a list of vertices
function NamedGraphs.to_graph_index(g::AbstractGraph, qv::QuotientVertex)
    return QuotientVertexVertices(qv.vertex, vertices(g, qv))
end

# NamedGraphs.to_vertices explictly converts to a collection of vertices, used for
# taking subgraphs.
NamedGraphs.to_vertices(g::AbstractGraph, qv::QuotientVertex) = qv[Vertices(vertices(g, qv))]

function NamedGraphs.to_vertices(g::AbstractGraph, qv::Vector{<:QuotientVertex})
    return NamedGraphs.to_vertices(g, QuotientVertices(map(v -> v.vertex, qv)))
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

function NamedGraphs.to_vertices(::AbstractGraph, qvs::Vector{<:QuotientVertexVertices})
    return QuotientVerticesVertices(qvs, mapreduce(collect, vcat, qvs))
end

function NamedGraphs.to_vertices(::AbstractGraph, qvs::Vector{<:QuotientVertexVertex})
    return QuotientVerticesVertices(qvs, collect(qvs))
end

function NamedGraphs.to_vertices(g::AbstractGraph, qvs::QuotientVertices)
    return QuotientVerticesVertices(qvs, mapreduce(qv -> collect(NamedGraphs.to_vertices(g, qv)), vcat, qvs))
end

Base.getindex(qvs::QuotientVerticesVertices, i) = qvs.vertices[i]

const QuotientVertexOrVerticesVertices = Union{QuotientVertexVertices, QuotientVerticesVertices}
