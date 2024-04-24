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

struct GenericNamedGraph{V,G<:AbstractSimpleGraph{Int}} <: AbstractNamedGraph{V}
  ordinal_graph::G
  ordered_vertices::Vector{V}
  vertex_to_ordinal_vertex::Dictionary{V,Int}
end

# AbstractNamedGraph required interface.
ordinal_graph_type(G::Type{<:GenericNamedGraph}) = fieldtype(G, :ordinal_graph)
ordinal_graph(graph::GenericNamedGraph) = getfield(graph, :ordinal_graph)
function vertex_to_ordinal_vertex(graph::GenericNamedGraph, vertex)
  return graph.vertex_to_ordinal_vertex[vertex]
end
function ordinal_vertex_to_vertex(graph::GenericNamedGraph, ordinal_vertex::Integer)
  return graph.ordered_vertices[ordinal_vertex]
end

# TODO: Decide what this should output.
# Graphs.vertices(graph::GenericNamedGraph) = graph.ordered_vertices
Graphs.vertices(graph::GenericNamedGraph) = keys(graph.vertex_to_ordinal_vertex)

function Graphs.add_vertex!(graph::GenericNamedGraph, vertex)
  if vertex ∈ vertices(graph)
    return false
  end
  add_vertex!(graph.ordinal_graph)
  # Update the forward map
  push!(graph.ordered_vertices, vertex)
  # Update the reverse map
  insert!(graph.vertex_to_ordinal_vertex, vertex, nv(graph.ordinal_graph))
  return true
end

function Graphs.rem_vertex!(graph::GenericNamedGraph, vertex)
  if vertex ∉ vertices(graph)
    return false
  end
  ordinal_vertex = graph.vertex_to_ordinal_vertex[vertex]
  rem_vertex!(graph.ordinal_graph, ordinal_vertex)
  # Insert the last vertex into the position of the vertex
  # that is being deleted, then remove the last vertex.
  last_vertex = last(graph.ordered_vertices)
  graph.ordered_vertices[ordinal_vertex] = last_vertex
  last_vertex = pop!(graph.ordered_vertices)
  graph.vertex_to_ordinal_vertex[last_vertex] = ordinal_vertex
  delete!(graph.vertex_to_ordinal_vertex, vertex)
  return true
end

function GraphsExtensions.rename_vertices(f::Function, g::GenericNamedGraph)
  # TODO: Could be implemented as `set_vertices(g, f.(g.ordered_vertices))`.
  return GenericNamedGraph(g.ordinal_graph, f.(g.ordered_vertices))
end

function GraphsExtensions.rename_vertices(f::Function, g::AbstractSimpleGraph)
  return error(
    "Can't rename the vertices of a graph of type `$(typeof(g)) <: AbstractSimpleGraph`, try converting to a named graph.",
  )
end

function GraphsExtensions.convert_vertextype(vertextype::Type, graph::GenericNamedGraph)
  return GenericNamedGraph(
    ordinal_graph(graph), convert(Vector{vertextype}, graph.ordered_vertices)
  )
end

#
# Convert inputs to vertex list
#

function to_vertices(vertices)
  return vec(collect(vertices))
end
to_vertices(vertices::Vector) = vertices
to_vertices(vertices::Array) = vec(vertices)
# Treat tuple inputs as cartesian grid sizes
function to_vertices(vertices::Tuple{Vararg{Integer}})
  return vec(Tuple.(CartesianIndices(vertices)))
end
to_vertices(vertices::Integer) = to_vertices(Base.OneTo(vertices))
function to_vertices(vertextype::Type, vertices)
  return convert(Vector{vertextype}, to_vertices(vertices))
end

#
# Constructors from `AbstractSimpleGraph`
#

# Inner constructor
function GenericNamedGraph{V,G}(
  ordinal_graph::AbstractSimpleGraph, vertices::Vector{V}
) where {V,G}
  @assert length(vertices) == nv(ordinal_graph)
  # Need to copy the vertices here, otherwise the Dictionary uses a view of the vertices
  return GenericNamedGraph{V,G}(
    ordinal_graph, vertices, Dictionary(copy(vertices), eachindex(vertices))
  )
end

function GenericNamedGraph{V,G}(ordinal_graph::AbstractSimpleGraph, vertices) where {V,G}
  return GenericNamedGraph{V,G}(ordinal_graph, to_vertices(V, vertices))
end

function GenericNamedGraph{V}(ordinal_graph::AbstractSimpleGraph, vertices) where {V}
  return GenericNamedGraph{V,typeof(ordinal_graph)}(ordinal_graph, vertices)
end

function GenericNamedGraph{<:Any,G}(
  ordinal_graph::AbstractSimpleGraph, vertices::Vector
) where {G}
  return GenericNamedGraph{eltype(vertices),G}(ordinal_graph, vertices)
end

function GenericNamedGraph{<:Any,G}(ordinal_graph::AbstractSimpleGraph, vertices) where {G}
  return GenericNamedGraph{<:Any,G}(ordinal_graph, to_vertices(vertices))
end

function GenericNamedGraph{<:Any,G}(ordinal_graph::AbstractSimpleGraph) where {G}
  return GenericNamedGraph{<:Any,G}(ordinal_graph, vertices(ordinal_graph))
end

function GenericNamedGraph(ordinal_graph::AbstractSimpleGraph, vertices::Vector)
  return GenericNamedGraph{eltype(vertices)}(ordinal_graph, vertices)
end

function GenericNamedGraph(ordinal_graph::AbstractSimpleGraph, vertices)
  return GenericNamedGraph(ordinal_graph, to_vertices(vertices))
end

function GenericNamedGraph(ordinal_graph::AbstractSimpleGraph)
  return GenericNamedGraph(ordinal_graph, vertices(ordinal_graph))
end

#
# Tautological constructors
#

GenericNamedGraph{V,G}(graph::GenericNamedGraph{V,G}) where {V,G} = copy(graph)

#
# Constructors from vertex names
#

function GenericNamedGraph{V,G}(vertices::Vector{V}) where {V,G}
  return GenericNamedGraph(G(length(vertices)), vertices)
end

function GenericNamedGraph{V,G}(vertices) where {V,G}
  return GenericNamedGraph{V,G}(to_vertices(V, vertices))
end

function GenericNamedGraph{V}(vertices) where {V}
  return GenericNamedGraph{V,SimpleGraph{Int}}(vertices)
end

function GenericNamedGraph{<:Any,G}(vertices) where {G}
  return GenericNamedGraph{eltype(vertices),G}(vertices)
end

function GenericNamedGraph(vertices)
  return GenericNamedGraph{eltype(vertices)}(vertices)
end

#
# Empty constructors
#

GenericNamedGraph{V,G}() where {V,G} = GenericNamedGraph{V,G}(V[])

GenericNamedGraph{V}() where {V} = GenericNamedGraph{V}(V[])

GenericNamedGraph{<:Any,G}() where {G} = GenericNamedGraph{<:Any,G}(Any[])

GenericNamedGraph() = GenericNamedGraph(Any[])

# TODO: implement as:
# graph = set_ordinal_graph(graph, copy(ordinal_graph(graph)))
# graph = set_vertices(graph, copy(vertices(graph)))
function Base.copy(graph::GenericNamedGraph)
  return GenericNamedGraph(copy(graph.ordinal_graph), copy(graph.ordered_vertices))
end

Graphs.edgetype(G::Type{<:GenericNamedGraph}) = NamedEdge{vertextype(G)}
Graphs.edgetype(graph::GenericNamedGraph) = edgetype(typeof(graph))

function GraphsExtensions.directed_graph_type(G::Type{<:GenericNamedGraph})
  return GenericNamedGraph{vertextype(G),directed_graph_type(ordinal_graph_type(G))}
end
function GraphsExtensions.undirected_graph_type(G::Type{<:GenericNamedGraph})
  return GenericNamedGraph{vertextype(G),undirected_graph_type(ordinal_graph_type(G))}
end

Graphs.is_directed(G::Type{<:GenericNamedGraph}) = is_directed(ordinal_graph_type(G))

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
