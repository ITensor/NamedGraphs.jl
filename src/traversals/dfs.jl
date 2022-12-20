@traitfn function topological_sort_by_dfs(g::AbstractNamedGraph::IsDirected)
  return parent_vertices_to_vertices(g, topological_sort_by_dfs(parent_graph(g)))
end

_dfs_tree(graph::AbstractNamedGraph, vertex; kwargs...) = tree(graph, dfs_parents(graph, vertex; kwargs...))
dfs_tree(graph::AbstractNamedGraph, vertex::Integer; kwargs...) = _dfs_tree(graph, vertex; kwargs...)
dfs_tree(graph::AbstractNamedGraph, vertex; kwargs...) = _dfs_tree(graph, vertex; kwargs...)

# Returns a Dictionary mapping a vertex to it's parent
# vertex in the traversal/spanning tree.
function _dfs_parents(graph::AbstractNamedGraph, vertex; kwargs...)
  parent_dfs_parents = dfs_parents(
    parent_graph(graph), vertex_to_parent_vertex(graph, vertex); kwargs...
  )
  return Dictionary(vertices(graph), parent_vertices_to_vertices(graph, parent_dfs_parents))
end
# Disambiguation from Graphs.dfs_tree
dfs_parents(graph::AbstractNamedGraph, vertex::Integer; kwargs...) = _dfs_parents(graph, vertex; kwargs...)
dfs_parents(graph::AbstractNamedGraph, vertex; kwargs...) = _dfs_parents(graph, vertex; kwargs...)
