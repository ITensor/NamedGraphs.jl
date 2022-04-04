struct NamedGraph{V,G<:AbstractGraph,B<:AbstractBijection} <: AbstractGraph{V}
  parent_graph::G
  vertex_to_parent_vertex::B # Invertible map from the vertices to the parent vertices
  function NamedGraph(parent_graph::G, vertex_to_parent_vertex::B) where {G<:AbstractGraph,B<:AbstractBijection}
    @assert issetequal(vertices(parent_graph), image(vertex_to_parent_vertex))
    V = domain_eltype(vertex_to_parent_vertex)
    return new{V,G,B}(parent_graph, vertex_to_parent_vertex)
  end
end
parent_graph(graph::NamedGraph) = graph.parent_graph
vertex_to_parent_vertex(graph::NamedGraph) = graph.vertex_to_parent_vertex
parent_vertex_to_vertex(graph::NamedGraph) = inv(vertex_to_parent_vertex(graph))
copy(graph::NamedGraph) = NamedGraph(copy(parent_graph(graph)), copy(vertex_to_parent_vertex(graph)))
vertices(graph::NamedGraph) = domain(vertex_to_parent_vertex(graph))

NamedGraph(vertices::Vector{T}) where T = NamedGraph{Graph{Int}}(vertices)
NamedDiGraph(vertices::Vector{T}) where T = NamedGraph{DiGraph{Int}}(vertices)

function NamedGraph(graph::AbstractGraph, vertices=default_vertices(graph))
  if length(vertices) != nv(graph)
    throw(ArgumentError("Vertices and parent graph's vertices must have equal length."))
  end
  if !allunique(vertices)
    throw(ArgumentError("Vertices have to be unique."))
  end

  vs = map(v -> CartesianKey(v), vertices)
  return NamedGraph(graph, bijection(MultiDimDictionary, Dictionary, vs, 1:length(vs)))
end

function NamedGraph(graph::AbstractGraph, dims::Tuple{Vararg{Integer}})
  return NamedGraph(graph, vec(Tuple.(CartesianIndices(dims))))
end

function NamedGraph(dims::Tuple{Vararg{Integer}})
  return NamedGraph(Graph(prod(dims)), vec(Tuple.(CartesianIndices(dims))))
end

function NamedGraph{S}(vertices::Vector) where {S<:AbstractGraph}
  return NamedGraph(S(length(vertices)), vertices)
end
