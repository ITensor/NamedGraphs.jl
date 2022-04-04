struct MultiDimGraph{V} <: AbstractNamedGraph{V}
  parent_graph::Graph{Int}
  vertices::Vector{V}
  vertex_to_parent_vertex::MultiDimDictionary{V,Int}
end

function MultiDimGraph{V}(parent_graph::Graph, vertices::Vector) where {V}
  return MultiDimGraph{V}(
    parent_graph, vertices, MultiDimDictionary{V}(vertices, eachindex(vertices))
  )
end

function MultiDimGraph(parent_graph::Graph, vertices::Vector)
  return MultiDimGraph{CartesianKey}(parent_graph, vertices)
end

# AbstractNamedGraph required interface.
parent_graph(graph::MultiDimGraph) = graph.parent_graph
vertices(graph::MultiDimGraph) = graph.vertices
function vertex_to_parent_vertex(graph::MultiDimGraph, vertex...)
  return graph.vertex_to_parent_vertex[vertex...]
end

# Customize obtaining subgraphs
function subvertices(graph::MultiDimGraph{V}, vertices::Vector) where {V}
  return convert(Vector{V}, vertices)
end

function subvertices(graph::MultiDimGraph, vertices...)
  return collect(keys(graph.vertex_to_parent_vertex[vertices...]))
end
