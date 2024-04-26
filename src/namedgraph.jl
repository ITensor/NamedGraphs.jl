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

struct GenericNamedGraph{V,G<:AbstractSimpleGraph{Int}} <: AbstractNamedGraph{V}
  one_based_graph::G
  vertices::OrderedIndices{V}
  global function _GenericNamedGraph(one_based_graph, vertices)
    @assert length(vertices) == nv(one_based_graph)
    return new{eltype(vertices),typeof(one_based_graph)}(one_based_graph, vertices)
  end
end

# AbstractNamedGraph required interface.
function one_based_graph_type(graph_type::Type{<:GenericNamedGraph})
  return fieldtype(graph_type, :one_based_graph)
end
one_based_graph(graph::GenericNamedGraph) = getfield(graph, :one_based_graph)

# TODO: Rename `vertex_positions(graph::GenericNamedGraph)`.
function vertex_to_one_based_vertex(graph::GenericNamedGraph, vertex)
  return OrderedDictionaries.index_positions(vertices(graph))[vertex]
end

# TODO: Rename `ordered_vertices(graph::GenericNamedGraph)`.
function one_based_vertex_to_vertex(graph::GenericNamedGraph, one_based_vertex::Integer)
  return vertices(graph)[one_based_vertex * th]
end

# TODO: Decide what this should output.
Graphs.vertices(graph::GenericNamedGraph) = getfield(graph, :vertices)

function Graphs.add_vertex!(graph::GenericNamedGraph, vertex)
  if vertex ∈ vertices(graph)
    return false
  end
  add_vertex!(one_based_graph(graph))
  insert!(vertices(graph), vertex)
  return true
end

function Graphs.rem_vertex!(graph::GenericNamedGraph, vertex)
  if vertex ∉ vertices(graph)
    return false
  end
  one_based_vertex = vertex_to_one_based_vertex(graph, vertex)
  rem_vertex!(one_based_graph(graph), one_based_vertex)
  delete!(vertices(graph), vertex)
  return graph
end

function GraphsExtensions.rename_vertices(f::Function, graph::GenericNamedGraph)
  # TODO: Fix broadcasting of `OrderedIndices`.
  # return GenericNamedGraph(one_based_graph(graph), f.(vertices(graph)))
  return GenericNamedGraph(one_based_graph(graph), map(f, vertices(graph)))
end

function GraphsExtensions.rename_vertices(f::Function, g::AbstractSimpleGraph)
  return error(
    "Can't rename the vertices of a graph of type `$(typeof(g)) <: AbstractSimpleGraph`, try converting to a named graph.",
  )
end

function GraphsExtensions.convert_vertextype(vertextype::Type, graph::GenericNamedGraph)
  return GenericNamedGraph(
    one_based_graph(graph), convert(Vector{vertextype}, graph.ordered_vertices)
  )
end

#
# Constructors from `AbstractSimpleGraph`
#

to_vertices(vertices) = vertices
to_vertices(vertices::AbstractArray) = vec(vertices)
to_vertices(vertices::Integer) = Base.OneTo(vertices)

# Inner constructor
# TODO: Is this needed?
function GenericNamedGraph{V,G}(
  one_based_graph::G, vertices::OrderedIndices{V}
) where {V,G<:AbstractSimpleGraph{Int}}
  return _GenericNamedGraph(one_based_graph, vertices)
end

function GenericNamedGraph{V,G}(
  one_based_graph::AbstractSimpleGraph, vertices
) where {V,G<:AbstractSimpleGraph{Int}}
  return GenericNamedGraph{V,G}(
    convert(G, one_based_graph), OrderedIndices{V}(to_vertices(vertices))
  )
end

function GenericNamedGraph{V}(one_based_graph::AbstractSimpleGraph, vertices) where {V}
  return GenericNamedGraph{V,typeof(one_based_graph)}(one_based_graph, vertices)
end

function GenericNamedGraph{<:Any,G}(
  one_based_graph::AbstractSimpleGraph, vertices
) where {G<:AbstractSimpleGraph{Int}}
  return GenericNamedGraph{eltype(vertices),G}(one_based_graph, vertices)
end

function GenericNamedGraph{<:Any,G}(
  one_based_graph::AbstractSimpleGraph
) where {G<:AbstractSimpleGraph{Int}}
  return GenericNamedGraph{<:Any,G}(one_based_graph, vertices(one_based_graph))
end

function GenericNamedGraph(one_based_graph::AbstractSimpleGraph, vertices)
  return GenericNamedGraph{eltype(vertices)}(one_based_graph, vertices)
end

function GenericNamedGraph(one_based_graph::AbstractSimpleGraph)
  return GenericNamedGraph(one_based_graph, vertices(one_based_graph))
end

#
# Tautological constructors
#

function GenericNamedGraph{V,G}(
  graph::GenericNamedGraph{V,G}
) where {V,G<:AbstractSimpleGraph{Int}}
  return copy(graph)
end

#
# Constructors from vertex names
#

function GenericNamedGraph{V,G}(vertices) where {V,G<:AbstractSimpleGraph{Int}}
  return GenericNamedGraph(G(length(to_vertices(vertices))), vertices)
end

function GenericNamedGraph{V}(vertices) where {V}
  return GenericNamedGraph{V,SimpleGraph{Int}}(vertices)
end

function GenericNamedGraph{<:Any,G}(vertices) where {G<:AbstractSimpleGraph{Int}}
  return GenericNamedGraph{eltype(vertices),G}(vertices)
end

function GenericNamedGraph(vertices)
  return GenericNamedGraph{eltype(vertices)}(vertices)
end

#
# Empty constructors
#

GenericNamedGraph{V,G}() where {V,G<:AbstractSimpleGraph{Int}} = GenericNamedGraph{V,G}(V[])

GenericNamedGraph{V}() where {V} = GenericNamedGraph{V}(V[])

function GenericNamedGraph{<:Any,G}() where {G<:AbstractSimpleGraph{Int}}
  return GenericNamedGraph{<:Any,G}(Any[])
end

GenericNamedGraph() = GenericNamedGraph(Any[])

# TODO: implement as:
# graph = set_one_based_graph(graph, copy(one_based_graph(graph)))
# graph = set_vertices(graph, copy(vertices(graph)))
function Base.copy(graph::GenericNamedGraph)
  return GenericNamedGraph(copy(one_based_graph(graph)), copy(vertices(graph)))
end

Graphs.edgetype(graph_type::Type{<:GenericNamedGraph}) = NamedEdge{vertextype(graph_type)}
Graphs.edgetype(graph::GenericNamedGraph) = edgetype(typeof(graph))

function GraphsExtensions.directed_graph_type(graph_type::Type{<:GenericNamedGraph})
  return GenericNamedGraph{
    vertextype(graph_type),directed_graph_type(one_based_graph_type(graph_type))
  }
end
function GraphsExtensions.undirected_graph_type(graph_type::Type{<:GenericNamedGraph})
  return GenericNamedGraph{
    vertextype(graph_type),undirected_graph_type(one_based_graph_type(graph_type))
  }
end

function Graphs.is_directed(graph_type::Type{<:GenericNamedGraph})
  return is_directed(one_based_graph_type(graph_type))
end

# TODO: Implement an edgelist version
function namedgraph_induced_subgraph(graph::AbstractGraph, subvertices)
  subgraph = typeof(graph)(subvertices)
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
  return namedgraph_induced_subgraph(graph, subvertices)
end

function Graphs.induced_subgraph(graph::AbstractNamedGraph, subvertices::Vector{<:Integer})
  return namedgraph_induced_subgraph(graph, subvertices)
end

#
# Type aliases
#

const NamedGraph{V} = GenericNamedGraph{V,SimpleGraph{Int}}
const NamedDiGraph{V} = GenericNamedGraph{V,SimpleDiGraph{Int}}
