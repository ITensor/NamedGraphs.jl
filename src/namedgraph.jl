struct NamedGraph{V} <: AbstractNamedGraph{V}
  parent_graph::Graph{Int}
  vertices::Vector{V}
  vertex_to_parent_vertex::Dictionary{V,Int}
end

is_directed(::Type{<:NamedGraph}) = false

function NamedGraph{V}(parent_graph::Graph, vertices::Vector{V}) where {V}
  return NamedGraph{V}(parent_graph, vertices, Dictionary(vertices, eachindex(vertices)))
end

function NamedGraph(parent_graph::Graph, vertices::Vector{V}) where {V}
  return NamedGraph{V}(parent_graph, vertices)
end

function NamedGraph(vertices::Vector)
  return NamedGraph(Graph(length(vertices)), vertices)
end

# AbstractNamedGraph required interface.
parent_graph(graph::NamedGraph) = graph.parent_graph
vertices(graph::NamedGraph) = graph.vertices
vertex_to_parent_vertex(graph::NamedGraph) = graph.vertex_to_parent_vertex
edgetype(graph::NamedGraph{V}) where {V} = NamedEdge{V}
