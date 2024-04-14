struct GenericNamedGraph{V,G<:AbstractSimpleGraph{Int}} <: AbstractNamedGraph{V}
  parent_graph::G
  parent_vertex_to_vertex::Vector{V}
  vertex_to_parent_vertex::Dictionary{V,Int}
end

# AbstractNamedGraph required interface.
parent_graph_type(G::Type{<:GenericNamedGraph}) = fieldtype(G, :parent_graph)
parent_graph(graph::GenericNamedGraph) = getfield(graph, :parent_graph)
function vertex_to_parent_vertex(graph::GenericNamedGraph, vertex)
  return graph.vertex_to_parent_vertex[vertex]
end
function parent_vertex_to_vertex(graph::GenericNamedGraph, parent_vertex)
  return graph.parent_vertex_to_vertex[parent_vertex]
end
vertices(graph::GenericNamedGraph) = keys(graph.vertex_to_parent_vertex)

function add_vertex!(graph::GenericNamedGraph, vertex)
  if vertex ∈ vertices(graph)
    return false
  end
  add_vertex!(graph.parent_graph)
  # Update the forward map
  push!(graph.parent_vertex_to_vertex, vertex)
  # Update the reverse map
  insert!(graph.vertex_to_parent_vertex, vertex, nv(graph.parent_graph))
  return true
end

function rem_vertex!(graph::GenericNamedGraph, vertex)
  if vertex ∉ vertices(graph)
    return false
  end
  parent_vertex = graph.vertex_to_parent_vertex[vertex]
  rem_vertex!(graph.parent_graph, parent_vertex)
  # Insert the last vertex into the position of the vertex
  # that is being deleted, then remove the last vertex.
  last_vertex = last(graph.parent_vertex_to_vertex)
  graph.parent_vertex_to_vertex[parent_vertex] = last_vertex
  last_vertex = pop!(graph.parent_vertex_to_vertex)
  # Insert the last vertex into the position of the vertex
  # that is being deleted, then remove the last vertex.
  graph.vertex_to_parent_vertex[last_vertex] = parent_vertex
  delete!(graph.vertex_to_parent_vertex, vertex)
  return true
end

function convert_vertextype(V::Type, graph::GenericNamedGraph)
  return GenericNamedGraph(parent_graph(graph), convert(Vector{V}, vertices(graph)))
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
function to_vertices(V::Type, vertices)
  return convert(Vector{V}, to_vertices(vertices))
end

#
# Constructors from `AbstractSimpleGraph`
#

# Inner constructor
function GenericNamedGraph{V,G}(
  parent_graph::AbstractSimpleGraph, vertices::Vector{V}
) where {V,G}
  @assert length(vertices) == nv(parent_graph)
  # Need to copy the vertices here, otherwise the Dictionary uses a view of the vertices
  return GenericNamedGraph{V,G}(
    parent_graph, vertices, Dictionary(copy(vertices), eachindex(vertices))
  )
end

function GenericNamedGraph{V,G}(parent_graph::AbstractSimpleGraph, vertices) where {V,G}
  return GenericNamedGraph{V,G}(parent_graph, to_vertices(V, vertices))
end

function GenericNamedGraph{V}(parent_graph::AbstractSimpleGraph, vertices) where {V}
  return GenericNamedGraph{V,typeof(parent_graph)}(parent_graph, vertices)
end

function GenericNamedGraph{<:Any,G}(
  parent_graph::AbstractSimpleGraph, vertices::Vector
) where {G}
  return GenericNamedGraph{eltype(vertices),G}(parent_graph, vertices)
end

function GenericNamedGraph{<:Any,G}(parent_graph::AbstractSimpleGraph, vertices) where {G}
  return GenericNamedGraph{<:Any,G}(parent_graph, to_vertices(vertices))
end

function GenericNamedGraph(parent_graph::AbstractSimpleGraph, vertices::Vector)
  return GenericNamedGraph{eltype(vertices)}(parent_graph, vertices)
end

function GenericNamedGraph(parent_graph::AbstractSimpleGraph, vertices)
  return GenericNamedGraph(parent_graph, to_vertices(vertices))
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

#
# Keyword argument constructor syntax
#

function GenericNamedGraph{V,G}(
  parent_graph::AbstractSimpleGraph; vertices=vertices(parent_graph)
) where {V,G}
  return GenericNamedGraph{V,G}(parent_graph, vertices)
end

function GenericNamedGraph{V}(
  parent_graph::AbstractSimpleGraph; vertices=vertices(parent_graph)
) where {V}
  return GenericNamedGraph{V}(parent_graph, vertices)
end

function GenericNamedGraph{<:Any,G}(
  parent_graph::AbstractSimpleGraph; vertices=vertices(parent_graph)
) where {G}
  return GenericNamedGraph{<:Any,G}(parent_graph, vertices)
end

function GenericNamedGraph(
  parent_graph::AbstractSimpleGraph; vertices=vertices(parent_graph)
)
  return GenericNamedGraph(parent_graph, vertices)
end

# TODO: implement as:
# graph = set_parent_graph(graph, copy(parent_graph(graph)))
# graph = set_vertices(graph, copy(vertices(graph)))
function copy(graph::GenericNamedGraph)
  return GenericNamedGraph(copy(parent_graph(graph)), copy(vertices(graph)))
end

edgetype(G::Type{<:GenericNamedGraph}) = NamedEdge{vertextype(G)}
edgetype(graph::GenericNamedGraph) = edgetype(typeof(graph))

function set_vertices(graph::GenericNamedGraph, vertices)
  return GenericNamedGraph(parent_graph(graph), vertices)
end

function directed_graph_type(G::Type{<:GenericNamedGraph})
  return GenericNamedGraph{vertextype(G),directed_graph(parent_graph_type(G))}
end
function undirected_graph_type(G::Type{<:GenericNamedGraph})
  return GenericNamedGraph{vertextype(G),undirected_graph(parent_graph_type(G))}
end

is_directed(G::Type{<:GenericNamedGraph}) = is_directed(parent_graph_type(G))

# TODO: Implement an edgelist version
function induced_subgraph(graph::AbstractNamedGraph, subvertices)
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

#
# Type aliases
#

const NamedGraph{V} = GenericNamedGraph{V,SimpleGraph{Int}}
const NamedDiGraph{V} = GenericNamedGraph{V,SimpleDiGraph{Int}}
