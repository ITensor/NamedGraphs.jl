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

quotient_index(vertices::Vertices) = QuotientVertices(parent_graph_indices(vertices))

Base.eltype(::QuotientVertices{V}) where {V} = QuotientVertex{V}

QuotientVertices(g::AbstractGraph) = QuotientVertices(keys(partitioned_vertices(g)))

NamedGraphs.parent_graph_indices(qvs::QuotientVertices) = qvs.vertices

function Base.iterate(qvs::QuotientVertices, state = nothing)
    if isnothing(state)
        out = iterate(qvs.vertices)
    else
        out = iterate(qvs.vertices, state)
    end
    if isnothing(out)
        return nothing
    else
        (v, s) = out
        return (QuotientVertex(v), s)
    end
end


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

# Replacing SubVertices
# TODO; Rename QuotientVertexVertices
struct QuotientVertexVertices{V, QV, Vs} <: AbstractVertices{V}
    quotients::QV
    vertices::Vs
    function QuotientVertexVertices(qv::QV, vertices::Vs) where {QV, Vs}
        V = eltype(vertices)
        return new{V, QV, Vs}(qv, vertices)
    end
end

quotients(qvs::QuotientVertexVertices) = getfield(qvs, :quotients)
departition(qvs::QuotientVertexVertices) = getfield(qvs, :vertices)

NamedGraphs.parent_graph_indices(qvs::QuotientVertexVertices) = departition(qvs)

# A single QuotientVertex and should index like a list of vertices
function NamedGraphs.to_graph_index(g::AbstractGraph, qv::QuotientVertex)
    return QuotientVertexVertices(qv, vertices(g, qv))
end
# QuotientVertices and should index like a list of quotient vertices
NamedGraphs.to_graph_index(::AbstractGraph, qv::QuotientVertices) = qv

const QuotientVerticesVertices{V, QV <: QuotientVertices, Vs} = QuotientVertexVertices{V, QV, Vs}

quotient_index(subvertices::QuotientVertexVertices) = quotients(subvertices)

# NamedGraphs.to_vertices explictly converts to a collection of vertices, used for
# taking subgraphs.
function NamedGraphs.to_vertices(g::AbstractGraph, qv::QuotientVertex)
    return QuotientVertexVertices(qv, vertices(g, qv))
end

function NamedGraphs.to_vertices(g::AbstractGraph, qv::QuotientVertices)
    return QuotientVertexVertices(qv, vertices(g, qv))
end

function NamedGraphs.to_vertices(g::AbstractGraph, qv::AbstractVector{<:QuotientVertex})
    return NamedGraphs.to_vertices(g, QuotientVertices(map(parent, qv)))
end
