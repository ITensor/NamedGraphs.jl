using Graphs: AbstractEdge

abstract type AbstractGraphIndices{T} end
abstract type AbstractVertices{V} <: AbstractGraphIndices{V} end
abstract type AbstractEdges{V, E <: AbstractEdge{V}} <: AbstractGraphIndices{E} end

struct Vertices{V, Vs} <: AbstractVertices{V}
    vertices::Vs
    Vertices(vertices::Vs) where {Vs} = new{eltype(Vs), Vs}(vertices)
end
struct Edges{V, E <: AbstractEdge{V}, Es} <: AbstractEdges{V, E}
    edges::Es
    function Edges(edges::Es) where {Es}
        E = eltype(Es)
        return new{vertextype{E}, E, Es}(edges)
    end
end

parent_graph_indices(vs::AbstractVertices) = vs.vertices
parent_graph_indices(es::AbstractEdges) = es.edges

# Interface
Base.eltype(::Type{<:AbstractGraphIndices{T}}) where {T} = T

Base.iterate(gi::AbstractGraphIndices) = iterate(parent_graph_indices(gi))
Base.iterate(gi::AbstractGraphIndices, state) = iterate(parent_graph_indices(gi), state)
Base.length(gi::AbstractGraphIndices) = length(parent_graph_indices(gi))

Base.getindex(gi::AbstractGraphIndices, ind) = parent_graph_indices(gi)[ind]

to_graph_indices(graph, indices) = indices
to_graph_indices(graph, indices::Pair) = edgetype(graph)(indices)
