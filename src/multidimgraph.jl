struct MultiDimGraph{V} <: AbstractNamedGraph{V}
  parent_graph::Graph{Int}
  vertices::Vector{V}
  vertex_to_parent_vertex::MultiDimDictionary{V,Int}
end

function MultiDimGraph{V}(parent_graph::Graph, vertices::Vector) where {V}
  graph_vertices = V.(vertices)
  return MultiDimGraph{V}(
    parent_graph, graph_vertices, MultiDimDictionary{V}(graph_vertices, eachindex(graph_vertices))
  )
end

function MultiDimGraph(parent_graph::Graph, vertices::Vector)
  # Could default to `eltype(vertices)`, but in general
  # we want the flexibility of `Tuple` for mixed key lengths
  # and types.
  return MultiDimGraph{Tuple}(parent_graph, vertices)
end

# AbstractNamedGraph required interface.
parent_graph(graph::MultiDimGraph) = graph.parent_graph
vertices(graph::MultiDimGraph) = graph.vertices
function vertex_to_parent_vertex(graph::MultiDimGraph, vertex...)
  return graph.vertex_to_parent_vertex[vertex...]
end

function has_vertex(graph::MultiDimGraph{V}, v::Tuple) where {V}
  return v in vertices(graph)
end

function has_vertex(graph::MultiDimGraph, v...)
  return has_vertex(graph, tuple(v...))
end

# Customize obtaining subgraphs
function subvertices(graph::MultiDimGraph{V}, vertices::Vector) where {V}
  return convert(Vector{V}, vertices)
end

function subvertices(graph::MultiDimGraph, vertices...)
  return collect(keys(graph.vertex_to_parent_vertex[vertices...]))
end
