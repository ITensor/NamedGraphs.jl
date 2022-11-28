struct GenericNamedGraph{V,G<:AbstractSimpleGraph{Int}} <: AbstractNamedGraph{V}
  parent_graph::G
  vertices::Vector{V}
  vertex_to_parent_vertex::Dictionary{V,Int}
end

#
# Constructors from `AbstractSimpleGraph`
#

# Inner constructor
function GenericNamedGraph{V,G}(parent_graph::AbstractSimpleGraph, vertices::Vector) where {V,G}
  # Need to copy the vertices here, otherwise the Dictionary uses a view of the vertices
  return GenericNamedGraph{V,G}(parent_graph, vertices, Dictionary(copy(vertices), eachindex(vertices)))
end

function GenericNamedGraph{V}(parent_graph::AbstractSimpleGraph, vertices::Vector) where {V}
  return GenericNamedGraph{V,typeof(parent_graph)}(parent_graph, vertices)
end

function GenericNamedGraph{<:Any,G}(parent_graph::AbstractSimpleGraph, vertices::Vector) where {G}
  return GenericNamedGraph{eltype(vertices),G}(parent_graph, vertices)
end

function GenericNamedGraph(parent_graph::AbstractSimpleGraph, vertices::Vector)
  # Need to copy the vertices here, otherwise the Dictionary uses a view of the vertices
  return GenericNamedGraph{eltype(vertices)}(parent_graph, vertices)
end

#
# Constructors from vertex names
#

function GenericNamedGraph{V,G}(vertices::Vector) where {V,G}
  return GenericNamedGraph(G(length(vertices)), vertices)
end

function GenericNamedGraph{V}(vertices::Vector) where {V}
  return GenericNamedGraph{V,SimpleGraph{Int}}(vertices)
end

function GenericNamedGraph{<:Any,G}(vertices::Vector) where {G}
  return GenericNamedGraph{Any,G}(vertices)
end

function GenericNamedGraph(vertices::Vector)
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

function GenericNamedGraph{V,G}(parent_graph::AbstractSimpleGraph; vertices=vertices(parent_graph)) where {V,G}
  return GenericNamedGraph{V,G}(parent_graph, vertices)
end

function GenericNamedGraph{V}(parent_graph::AbstractSimpleGraph; vertices=vertices(parent_graph)) where {V}
  return GenericNamedGraph{V}(parent_graph, vertices)
end

function GenericNamedGraph{<:Any,G}(parent_graph::AbstractSimpleGraph; vertices=vertices(parent_graph)) where {G}
  return GenericNamedGraph{<:Any,G}(parent_graph, vertices)
end

function GenericNamedGraph(parent_graph::AbstractSimpleGraph; vertices=vertices(parent_graph))
  return GenericNamedGraph(parent_graph, vertices)
end

#
# Convenient cartesian index constructor
#

function GenericNamedGraph{V,G}(parent_graph::AbstractSimpleGraph, grid_size::Tuple{Vararg{Int}}) where {V,G}
  vertices = Tuple.(CartesianIndices(grid_size))
  @assert prod(grid_size) == nv(parent_graph)
  return GenericNamedGraph{V,G}(parent_graph, vec(vertices))
end

function GenericNamedGraph{V}(parent_graph::AbstractSimpleGraph, grid_size::Tuple{Vararg{Int}}) where {V}
  return GenericNamedGraph{V,typeof(parent_graph)}(parent_graph, grid_size)
end

function GenericNamedGraph{<:Any,G}(parent_graph::AbstractSimpleGraph, grid_size::Tuple{Vararg{Int}}) where {G}
  return GenericNamedGraph{typeof(grid_size),G}(parent_graph, grid_size)
end

function GenericNamedGraph(parent_graph::AbstractSimpleGraph, grid_size::Tuple{Vararg{Int}})
  return GenericNamedGraph{typeof(grid_size),typeof(parent_graph)}(parent_graph, grid_size)
end

# AbstractNamedGraph required interface.
# TODO: rename `parent_graph` (type is implied by input)
parent_graph_type(::Type{<:GenericNamedGraph{V,G}}) where {V,G} = G
parent_graph(graph::GenericNamedGraph) = graph.parent_graph
vertices(graph::GenericNamedGraph) = graph.vertices
vertex_to_parent_vertex(graph::GenericNamedGraph) = graph.vertex_to_parent_vertex

# TODO: implement as:
# graph = set_parent_graph(graph, copy(parent_graph(graph)))
# graph = set_vertices(graph, copy(vertices(graph)))
copy(graph::GenericNamedGraph) = GenericNamedGraph(copy(parent_graph(graph)), copy(vertices(graph)))

edgetype(G::Type{<:GenericNamedGraph}) = NamedEdge{vertextype(G)}
edgetype(graph::GenericNamedGraph) = edgetype(typeof(graph))

function set_vertices(graph::GenericNamedGraph, vertices)
  return GenericNamedGraph(parent_graph(graph), vertices)
end

directed_graph(G::Type{<:GenericNamedGraph}) = GenericNamedGraph{vertextype(G),directed_graph(parent_graph_type(G))}
undirected_graph(G::Type{<:GenericNamedGraph}) = GenericNamedGraph{vertextype(G),undirected_graph(parent_graph_type(G))}

is_directed(G::Type{<:GenericNamedGraph}) = is_directed(parent_graph_type(G))

# TODO: Implement an edgelist version
function induced_subgraph(graph::AbstractNamedGraph, subvertices::Vector)
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
