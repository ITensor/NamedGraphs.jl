using Graphs: Graphs, dfs_parents, dfs_tree, topological_sort_by_dfs
using SimpleTraits: SimpleTraits, @traitfn

@traitfn function Graphs.topological_sort_by_dfs(g::AbstractNamedGraph::IsDirected)
  return parent_vertices_to_vertices(g, topological_sort_by_dfs(parent_graph(g)))
end

function namedgraph_dfs_tree(graph::AbstractNamedGraph, vertex; kwargs...)
  return Graphs.tree(graph, dfs_parents(graph, vertex; kwargs...))
end
function Graphs.dfs_tree(graph::AbstractNamedGraph, vertex::Integer; kwargs...)
  return namedgraph_dfs_tree(graph, vertex; kwargs...)
end
function Graphs.dfs_tree(graph::AbstractNamedGraph, vertex; kwargs...)
  return namedgraph_dfs_tree(graph, vertex; kwargs...)
end

# Returns a Dictionary mapping a vertex to it's parent
# vertex in the traversal/spanning tree.
function namedgraph_dfs_parents(graph::AbstractNamedGraph, vertex; kwargs...)
  parent_dfs_parents = dfs_parents(
    parent_graph(graph), vertex_to_parent_vertex(graph, vertex); kwargs...
  )
  # Works around issue in this `Dictionary` constructor:
  # https://github.com/andyferris/Dictionaries.jl/blob/v0.4.1/src/Dictionary.jl#L139-L145
  # when `inds` has holes. This removes the holes.
  # TODO: Raise an issue with `Dictionaries.jl`.
  ## vertices_graph = Indices(collect(vertices(graph)))
  # This makes the vertices ordered according to the parent vertices.
  vertices_graph = parent_vertices_to_vertices(graph, parent_vertices(graph))
  return Dictionary(vertices_graph, parent_vertices_to_vertices(graph, parent_dfs_parents))
end
# Disambiguation from Graphs.dfs_parents
function Graphs.dfs_parents(graph::AbstractNamedGraph, vertex::Integer; kwargs...)
  return namedgraph_dfs_parents(graph, vertex; kwargs...)
end
function Graphs.dfs_parents(graph::AbstractNamedGraph, vertex; kwargs...)
  return namedgraph_dfs_parents(graph, vertex; kwargs...)
end
