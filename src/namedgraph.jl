using Dictionaries: Dictionary
using Graphs:
    Graphs,
    AbstractGraph,
    add_edge!,
    add_vertex!,
    edgetype,
    has_edge,
    is_directed,
    outneighbors,
    rem_vertex!,
    vertices
using Graphs.SimpleGraphs: AbstractSimpleGraph, SimpleDiGraph, SimpleGraph
using .GraphsExtensions:
    GraphsExtensions, vertextype, directed_graph_type, undirected_graph_type
using .OrderedDictionaries: OrderedDictionaries, OrderedIndices
using .OrdinalIndexing: th

struct GenericNamedGraph{V, G <: AbstractSimpleGraph{Int}} <: AbstractNamedGraph{V}
    position_graph::G
    vertices::OrderedIndices{V}
    global function _GenericNamedGraph(position_graph, vertices)
        @assert length(vertices) == nv(position_graph)
        return new{eltype(vertices), typeof(position_graph)}(position_graph, vertices)
    end
end

# AbstractNamedGraph required interface.
function position_graph_type(graph_type::Type{<:GenericNamedGraph})
    return fieldtype(graph_type, :position_graph)
end
position_graph(graph::GenericNamedGraph) = getfield(graph, :position_graph)
function vertex_positions(graph::GenericNamedGraph)
    return OrderedDictionaries.index_positions(vertices(graph))
end
function ordered_vertices(graph::GenericNamedGraph)
    return OrderedDictionaries.ordered_indices(vertices(graph))
end

# TODO: Decide what this should output.
Graphs.vertices(graph::GenericNamedGraph) = getfield(graph, :vertices)

function Graphs.add_vertex!(graph::GenericNamedGraph, vertex)
    if vertex ∈ vertices(graph)
        return false
    end
    add_vertex!(position_graph(graph))
    insert!(vertices(graph), vertex)
    return true
end

function Graphs.rem_vertex!(graph::GenericNamedGraph, vertex)
    if vertex ∉ vertices(graph)
        return false
    end
    position_vertex = vertex_positions(graph)[vertex]
    rem_vertex!(position_graph(graph), position_vertex)
    delete!(vertices(graph), vertex)
    return graph
end

function GraphsExtensions.rename_vertices(f::Function, graph::GenericNamedGraph)
    # TODO: Fix broadcasting of `OrderedIndices`.
    # return GenericNamedGraph(position_graph(graph), f.(vertices(graph)))
    return GenericNamedGraph(position_graph(graph), map(f, vertices(graph)))
end

function GraphsExtensions.rename_vertices(f::Function, g::AbstractSimpleGraph)
    return error(
        "Can't rename the vertices of a graph of type `$(typeof(g)) <: AbstractSimpleGraph`, try converting to a named graph.",
    )
end

function GraphsExtensions.convert_vertextype(vertextype::Type, graph::GenericNamedGraph)
    return GenericNamedGraph(
        position_graph(graph), convert(Vector{vertextype}, ordered_vertices(graph))
    )
end

#
# Constructors from `AbstractSimpleGraph`
#

to_vertices(graph, vertices) = to_vertices(vertices)
to_vertices(vertices) = vertices
to_vertices(vertices::AbstractArray) = vec(vertices)
to_vertices(vertices::Integer) = Base.OneTo(vertices)

# Inner constructor
# TODO: Is this needed?
function GenericNamedGraph{V, G}(
        position_graph::G, vertices::OrderedIndices{V}
    ) where {V, G <: AbstractSimpleGraph{Int}}
    return _GenericNamedGraph(position_graph, vertices)
end

function GenericNamedGraph{V, G}(
        position_graph::AbstractSimpleGraph, vertices
    ) where {V, G <: AbstractSimpleGraph{Int}}
    return GenericNamedGraph{V, G}(
        convert(G, position_graph), OrderedIndices{V}(to_vertices(position_graph, vertices))
    )
end

function GenericNamedGraph{V}(position_graph::AbstractSimpleGraph, vertices) where {V}
    return GenericNamedGraph{V, typeof(position_graph)}(position_graph, vertices)
end

function GenericNamedGraph{<:Any, G}(
        position_graph::AbstractSimpleGraph, vertices
    ) where {G <: AbstractSimpleGraph{Int}}
    return GenericNamedGraph{eltype(vertices), G}(position_graph, vertices)
end

function GenericNamedGraph{<:Any, G}(
        position_graph::AbstractSimpleGraph
    ) where {G <: AbstractSimpleGraph{Int}}
    return GenericNamedGraph{<:Any, G}(position_graph, vertices(position_graph))
end

function GenericNamedGraph(position_graph::AbstractSimpleGraph, vertices)
    return GenericNamedGraph{eltype(vertices)}(position_graph, vertices)
end

function GenericNamedGraph(position_graph::AbstractSimpleGraph)
    return GenericNamedGraph(position_graph, vertices(position_graph))
end

#
# Tautological constructors
#

function GenericNamedGraph{V, G}(
        graph::GenericNamedGraph{V, G}
    ) where {V, G <: AbstractSimpleGraph{Int}}
    return copy(graph)
end

#
# Constructors from vertex names
#

function GenericNamedGraph{V, G}(vertices) where {V, G <: AbstractSimpleGraph{Int}}
    return GenericNamedGraph(G(length(to_vertices(vertices))), vertices)
end

function GenericNamedGraph{V}(vertices) where {V}
    return GenericNamedGraph{V, SimpleGraph{Int}}(vertices)
end

function GenericNamedGraph{<:Any, G}(vertices) where {G <: AbstractSimpleGraph{Int}}
    return GenericNamedGraph{eltype(vertices), G}(vertices)
end

function GenericNamedGraph(vertices)
    return GenericNamedGraph{eltype(vertices)}(vertices)
end

#
# Empty constructors
#

GenericNamedGraph{V, G}() where {V, G <: AbstractSimpleGraph{Int}} = GenericNamedGraph{V, G}(V[])

GenericNamedGraph{V}() where {V} = GenericNamedGraph{V}(V[])

function GenericNamedGraph{<:Any, G}() where {G <: AbstractSimpleGraph{Int}}
    return GenericNamedGraph{<:Any, G}(Any[])
end

GenericNamedGraph() = GenericNamedGraph(Any[])

function GenericNamedGraph(graph::GenericNamedGraph)
    return GenericNamedGraph{vertextype(graph), position_graph_type(graph)}(graph)
end
function GenericNamedGraph{V}(graph::GenericNamedGraph) where {V}
    return GenericNamedGraph{V, position_graph_type(graph)}(graph)
end
function GenericNamedGraph{<:Any, G}(
        graph::GenericNamedGraph
    ) where {G <: AbstractSimpleGraph{Int}}
    return GenericNamedGraph{vertextype(graph), G}(graph)
end
function GenericNamedGraph{V, G}(
        graph::GenericNamedGraph
    ) where {V, G <: AbstractSimpleGraph{Int}}
    return GenericNamedGraph{V, G}(copy(position_graph(graph)), copy(vertices(graph)))
end

function Base.convert(graph_type::Type{<:GenericNamedGraph}, graph::GenericNamedGraph)
    return graph_type(graph)
end

# TODO: implement as:
# graph = set_position_graph(graph, copy(position_graph(graph)))
# graph = set_vertices(graph, copy(vertices(graph)))
function Base.copy(graph::GenericNamedGraph)
    return GenericNamedGraph(copy(position_graph(graph)), copy(vertices(graph)))
end

Graphs.edgetype(graph_type::Type{<:GenericNamedGraph}) = NamedEdge{vertextype(graph_type)}

function GraphsExtensions.directed_graph_type(graph_type::Type{<:GenericNamedGraph})
    return GenericNamedGraph{
        vertextype(graph_type), directed_graph_type(position_graph_type(graph_type)),
    }
end
function GraphsExtensions.undirected_graph_type(graph_type::Type{<:GenericNamedGraph})
    return GenericNamedGraph{
        vertextype(graph_type), undirected_graph_type(position_graph_type(graph_type)),
    }
end

function Graphs.is_directed(graph_type::Type{<:GenericNamedGraph})
    return is_directed(position_graph_type(graph_type))
end

# Assumes the subvertices were already processed by `to_vertices`.
# TODO: Implement an edgelist version
function induced_subgraph_from_vertices(graph::AbstractGraph, subvertices)
    subgraph = similar_graph(graph, subvertices)
    subvertices_set = Set(subvertices)
    for src in subvertices
        for dst in outneighbors(graph, src)
            if dst in subvertices_set && has_edge(graph, src, dst)
                add_edge!(subgraph, src => dst)
            end
        end
    end
    return subgraph, nothing
end

function Graphs.induced_subgraph(graph::AbstractNamedGraph, subvertices)
    return induced_subgraph_from_vertices(graph, to_vertices(graph, subvertices))
end
# For method ambiguity resolution with Graphs.jl
function Graphs.induced_subgraph(
        graph::AbstractNamedGraph, subvertices::AbstractVector{<:Integer}
    )
    return induced_subgraph_from_vertices(graph, to_vertices(graph, subvertices))
end

function Base.reverse!(graph::GenericNamedGraph)
    reverse!(graph.position_graph)
    return graph
end
function Base.reverse(graph::GenericNamedGraph)
    return GenericNamedGraph(reverse(graph.position_graph), copy(graph.vertices))
end

#
# Type aliases
#

const NamedGraph{V} = GenericNamedGraph{V, SimpleGraph{Int}}
const NamedDiGraph{V} = GenericNamedGraph{V, SimpleDiGraph{Int}}
