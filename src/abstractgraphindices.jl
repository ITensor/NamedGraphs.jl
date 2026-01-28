using Graphs: AbstractEdge
using Dictionaries: Dictionaries

abstract type AbstractGraphIndices{T} end
abstract type AbstractVertices{V} <: AbstractGraphIndices{V} end
abstract type AbstractEdges{V, E <: AbstractEdge{V}} <: AbstractGraphIndices{E} end

struct Vertices{V, Vs} <: AbstractVertices{V}
    vertices::Vs
    Vertices(vertices::Vs) where {Vs} = new{eltype(Vs), Vs}(vertices)
end

to_vertices(graph, vertices::AbstractVector) = Vertices(vertices)
to_vertices(graph, vertices::AbstractVertices) = vertices

struct Edges{V, E <: AbstractEdge{V}, Es} <: AbstractEdges{V, E}
    edges::Es
    function Edges(edges::Es) where {Es}
        E = eltype(Es)
        return new{vertextype(E), E, Es}(edges)
    end
end

to_edges(graph, edges) = edges
to_edges(graph, edges::AbstractVector{<:AbstractEdge}) = Edges(edges)
function to_edges(graph, edges::AbstractVector{<:Pair})
    return to_edges(graph, map(i -> to_graph_index(graph, i), edges))
end

parent_graph_indices(vs::AbstractVertices) = vs.vertices
parent_graph_indices(es::AbstractEdges) = es.edges

# Interface
Base.eltype(::Type{<:AbstractGraphIndices{T}}) where {T} = T

Base.length(gi::AbstractGraphIndices) = length(parent_graph_indices(gi))

# Canonize assuming nothing about `index`.
to_graph_index(graph, index) = index
to_graph_index(graph, index::Pair) = edgetype(graph)(index)

to_graph_index(graph, inds::AbstractVector{<:Pair}) = map(i -> to_graph_index(graph, i), inds)

Base.iterate(gi::AbstractGraphIndices, state...) = iterate(parent_graph_indices(gi), state...)

Base.getindex(gi::AbstractGraphIndices, i) = getindex(parent_graph_indices(gi), i)

Base.getindex(graph::AbstractNamedGraph, inds) = getindex_namedgraph(graph, to_graph_index(graph, inds))

getindex_namedgraph(graph::AbstractGraph, inds) = get_graph_index(graph, inds)
getindex_namedgraph(graph::AbstractGraph, inds::AbstractGraphIndices) = get_graph_indices(graph, inds)

get_graph_index(graph::AbstractGraph, index) = throw(MethodError(get_graph_index, (graph, index)))

function Dictionaries.getindices(graph::AbstractNamedGraph, inds)
    return get_graph_indices(graph, to_graph_index(graph, inds))
end

function get_graph_indices(graph::AbstractGraph, vertices::AbstractVertices)
    return subgraph(graph, vertices)
end
function get_graph_indices(graph::AbstractGraph, edges::AbstractEdges)
    return edge_subgraph(graph, edges)
end
