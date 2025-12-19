using Graphs: AbstractEdge

abstract type AbstractGraphIndices{T} end
abstract type AbstractVertices{V} <: AbstractGraphIndices{V} end
abstract type AbstractEdges{V, E <: AbstractEdge{V}} <: AbstractGraphIndices{E} end

struct Vertices{V, Vs} <: AbstractVertices{V}
    vertices::Vs
    Vertices(vertices::Vs) where {Vs} = new{eltype(Vs), Vs}(vertices)
end

Vertices(v1, v2, vertices...) = Vertices(vcat([v1, v2], collect(vertices)))

struct Edges{V, E <: AbstractEdge{V}, Es} <: AbstractEdges{V, E}
    edges::Es
    function Edges(edges::Es) where {Es}
        E = eltype(Es)
        return new{vertextype(E), E, Es}(edges)
    end
end

Edges(e1, e2, edges...) = Edges(vcat([e1, e2], collect(edges)))

parent_graph_indices(vs::AbstractVertices) = vs.vertices
parent_graph_indices(es::AbstractEdges) = es.edges

# Interface
Base.eltype(::Type{<:AbstractGraphIndices{T}}) where {T} = T

Base.length(gi::AbstractGraphIndices) = length(parent_graph_indices(gi))

to_graph_index(graph, index) = index
to_graph_index(graph, index::Pair) = edgetype(graph)(index)

Base.iterate(gi::AbstractGraphIndices, state = nothing) = iterate_graph_indices(identity, gi, state)
function iterate_graph_indices(f, gi::AbstractGraphIndices, state)
    if isnothing(state)
        out = iterate(parent_graph_indices(gi))
    else
        out = iterate(parent_graph_indices(gi), state)
    end
    if isnothing(out)
        return nothing
    else
        (v, s) = out
        return (f(v), s)
    end
end

Base.getindex(gi::AbstractGraphIndices, i) = getindex(parent_graph_indices(gi), i)
