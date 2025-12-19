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

quotient_index(vertex) = QuotientVertex(vertex)

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

QuotientVertices(vertices...) = QuotientVertices(collect(vertices))

quotient_index(vertices::Vertices) = QuotientVertices(parent_graph_indices(vertices))

Base.eltype(::QuotientVertices{V}) where {V} = QuotientVertex{V}

QuotientVertices(g::AbstractGraph) = QuotientVertices(keys(partitioned_vertices(g)))

NamedGraphs.parent_graph_indices(qvs::QuotientVertices) = qvs.vertices

function Base.iterate(qvs::QuotientVertices, state = nothing)
    return NamedGraphs.iterate_graph_indices(QuotientVertex, qvs, state)
end

Base.getindex(qvs::QuotientVertices, i::Int) = QuotientVertex(parent_graph_indices(qvs)[i])

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

quotient_index(qvv::QuotientVertexVertex) = QuotientVertex(qvv.quotientvertex)

Base.getindex(qv::QuotientVertex, v) = QuotientVertexVertex(parent(qv), v)
function Base.getindex(qv::QuotientVertex, v::Vertices)
    return QuotientVertexVertices(parent(qv), parent_graph_indices(v))
end

GraphsExtensions.vertextype(::Type{<:QuotientVertexVertex{V}}) where {V} = V
GraphsExtensions.vertextype(::Type{<:QuotientVertexVertex}) = Any

quotient_vertextype(::Type{<:QuotientVertexVertex{V, QV}}) where {V, QV} = QV

NamedGraphs.to_vertices(g, qvv::QuotientVertexVertex) = quotient_index(qvv)[Vertices([qvv.vertex])]

# Represents multiple vertices in a QuotientVertex
struct QuotientVertexVertices{V, QV, Vs} <: AbstractVertices{V}
    quotientvertex::QV
    vertices::Vs
    function QuotientVertexVertices(qv::QV, vertices::Vs) where {QV, Vs}
        V = eltype(vertices)
        return new{V, QV, Vs}(qv, vertices)
    end
end

quotient_index(qvv::QuotientVertexVertices) = QuotientVertex(qvv.quotientvertex)

Base.eltype(::QuotientVertexVertices{V, QV}) where {V, QV} = QuotientVertexVertex{V, QV}
# GraphsExtensions.vertextype(::Type{<:QuotientVertexVertices{V}}) where {V} = V
# quotient_vertextype(::Type{<:QuotientVertexVertices{V, QV}}) where {V, QV} = QV

departition(qvs::QuotientVertexVertices) = getfield(qvs, :vertices)

NamedGraphs.parent_graph_indices(qvs::QuotientVertexVertices) = departition(qvs)

function Base.iterate(qvs::QuotientVertexVertices, state = nothing)
    return NamedGraphs.iterate_graph_indices(v -> quotient_index(qvs)[v], qvs, state)
end

function Base.getindex(qvs::QuotientVertexVertices, i::Int)
    return quotient_index(qvs)[parent_graph_indices(qvs)[i]]
end
function Base.getindex(qvs::QuotientVertexVertices, i)
    return quotient_index(qvs)[Vertices(parent_graph_indices(qvs)[i])]
end

# A single QuotientVertex and should index like a list of vertices
function NamedGraphs.to_graph_index(g::AbstractGraph, qv::QuotientVertex)
    return QuotientVertexVertices(parent(qv), vertices(g, qv))
end
# QuotientVertices and should index like a list of quotient vertices
NamedGraphs.to_graph_index(::AbstractGraph, qv::QuotientVertices) = qv

# NamedGraphs.to_vertices explictly converts to a collection of vertices, used for
# taking subgraphs.
NamedGraphs.to_vertices(g::AbstractGraph, qv::QuotientVertex) = qv[Vertices(vertices(g, qv))]

function NamedGraphs.to_vertices(g::AbstractGraph, qv::Vector{<:QuotientVertex})
    return NamedGraphs.to_vertices(g, QuotientVertices(map(parent, qv)))
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

quotient_index(qvs::QuotientVerticesVertices) = qvs.quotientvertices

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
