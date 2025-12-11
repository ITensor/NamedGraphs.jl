using Graphs: AbstractEdge

abstract type AbstractGraphIndices{T} <: AbstractVector{T} end
abstract type AbstractVertices{V} <: AbstractGraphIndices{V} end
abstract type AbstractEdges{V, E <: AbstractEdge{V}} <: AbstractGraphIndices{E} end

struct Vertices{V} <: AbstractVertices{V}
    vertices::Vector{V}
end
struct Edges{V, E} <: AbstractEdges{V, E}
    edges::Vector{E}
    Edges(edges::Vector{E}) where {V, E <: AbstractEdge{V}} = new{V, E}(edges)
end

Graphs.vertices(vs::Vertices) = vs.vertices
Graphs.edges(es::Edges) = es.edges

# Interface
Base.iterate(vs::AbstractVertices) = iterate(vertices(vs))
Base.iterate(vs::AbstractVertices, state) = iterate(vertices(vs), state)

Base.iterate(es::AbstractEdges) = iterate(edges(es))
Base.iterate(es::AbstractEdges, state) = iterate(edges(es), state)

Base.length(gi::AbstractVertices) = length(vertices(gi))
Base.length(es::AbstractEdges) = length(edges(es))

# These make `show` work
Base.size(gi::AbstractGraphIndices) = (length(gi),)
Base.getindex(vs::AbstractVertices, vertex) = vertices(vs)[vertex]
Base.getindex(es::AbstractEdges, vertex) = edges(es)[vertex]

Base.IteratorSize(::Type{<:AbstractGraphIndices}) = Base.HasLength()

# Derived

Base.eltype(::AbstractGraphIndices{T}) where {T} = T

to_graph_indices(graph, indices) = indices
to_graph_indices(graph, indices::Pair) = edgetype(graph)(indices)
