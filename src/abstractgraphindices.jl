using Dictionaries: Dictionaries
using Graphs: AbstractEdge, vertices

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

to_edges(graph, edge::AbstractEdge) = to_edges(graph, [edge])
to_edges(graph, pair::Pair) = to_edges(graph, to_graph_index(graph, pair))

to_edges(graph, edges::AbstractVector{<:AbstractEdge}) = Edges(edges)
function to_edges(graph, edges::AbstractVector{<:Pair})
    return to_edges(graph, map(i -> to_graph_index(graph, i), edges))
end

parent_graph_indices(vs::AbstractVertices) = vs.vertices
parent_graph_indices(es::AbstractEdges) = es.edges

# Interface
Base.eltype(::Type{<:AbstractGraphIndices{T}}) where {T} = T

Base.length(gi::AbstractGraphIndices) = length(parent_graph_indices(gi))

"""
    to_graph_index(graph, index)

Canonicalize `index` into the index type that `graph` is indexed by, for example
turning a `Pair` of vertices into an edge of `edgetype(graph)`. Indices that are
already canonical are returned unchanged.

The indexing entry points call this on the index they are given, so overload it to
teach a graph type or an index type a new spelling of a vertex or an edge. That
covers writes as well as reads: downstream routes `setindex!` and `isassigned`
through it too, not only `getindex`. The first argument is
deliberately untyped, so anything indexed by vertices and edges can use it rather
than graphs alone.
"""
to_graph_index(graph, index) = index
to_graph_index(graph, index::Pair) = edgetype(graph)(index)

function to_graph_index(graph, inds::AbstractVector{<:Pair})
    return to_graph_index(graph, map(i -> to_graph_index(graph, i), inds))
end
to_graph_index(graph, inds::AbstractVector{<:AbstractEdge}) = Edges(inds)

function Base.iterate(gi::AbstractGraphIndices, state...)
    return iterate(parent_graph_indices(gi), state...)
end

Base.getindex(gi::AbstractGraphIndices, i) = getindex(parent_graph_indices(gi), i)

function Base.getindex(graph::AbstractNamedGraph, inds)
    return getindex_namedgraph(graph, to_graph_index(graph, inds))
end

getindex_namedgraph(graph::AbstractGraph, inds) = get_graph_index(graph, inds)
function getindex_namedgraph(graph::AbstractGraph, inds::AbstractGraphIndices)
    return get_graph_indices(graph, inds)
end

function get_graph_index(graph::AbstractGraph, index)
    throw(MethodError(get_graph_index, (graph, index)))
end

function Dictionaries.getindices(graph::AbstractNamedGraph, inds)
    return get_graph_indices(graph, to_graph_index(graph, inds))
end

# Indexing.jl and Dictionaries.jl dispatch `getindices` on the index container,
# which ties with the untyped `inds` above, so each of those containers needs a
# method here. A `Colon` is an indexing convention rather than a plausible
# vertex, so it means every vertex.
function Dictionaries.getindices(graph::AbstractNamedGraph, ::Colon)
    return getindex_namedgraph(graph, to_vertices(graph, collect(vertices(graph))))
end

# An `AbstractIndices` is a set of vertices rather than a lookup table, and
# `vertices(graph)` is itself one, so this has to be more specific than the
# `AbstractDictionary` method below.
function Dictionaries.getindices(
        graph::AbstractNamedGraph, inds::Dictionaries.AbstractIndices
    )
    return getindex_namedgraph(graph, to_vertices(graph, collect(inds)))
end

# A dictionary mapping keys to values has no meaning as a graph index.
for T in (:AbstractDict, :(Dictionaries.AbstractDictionary))
    @eval function Dictionaries.getindices(graph::AbstractNamedGraph, inds::$T)
        throw(
            ArgumentError(
                "Can't index a graph by a dictionary. Index by a collection of vertices or edges instead."
            )
        )
    end
end

function get_graph_indices(graph::AbstractGraph, vertices::AbstractVertices)
    return subgraph(graph, vertices)
end
function get_graph_indices(graph::AbstractGraph, edges::AbstractEdges)
    return edge_subgraph(graph, edges)
end
