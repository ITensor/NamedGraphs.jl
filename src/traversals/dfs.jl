@traitfn function topological_sort_by_dfs(g::AbstractNamedGraph::IsDirected)
  return parent_vertices_to_vertices(g, topological_sort_by_dfs(parent_graph(g)))
end

function _dfs_tree(graph::AbstractNamedGraph, vertex; kwargs...)
  return tree(graph, dfs_parents(graph, vertex; kwargs...))
end
function dfs_tree(graph::AbstractNamedGraph, vertex::Integer; kwargs...)
  return _dfs_tree(graph, vertex; kwargs...)
end
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
function dfs_parents(graph::AbstractNamedGraph, vertex::Integer; kwargs...)
  return _dfs_parents(graph, vertex; kwargs...)
end
function dfs_parents(graph::AbstractNamedGraph, vertex; kwargs...)
  return _dfs_parents(graph, vertex; kwargs...)
end

#Given a graph, split it into its connected components, construct a spanning tree over each of them
# and take the union (adding in edges between the trees to recover a connected graph)
function spanning_forest(
  g::AbstractNamedGraph;
  tree_constructor=g ->
    undirected_graph(bfs_tree(g, first(keys(sort(eccentricities(g); rev=true))))),
)
  component_vertices = connected_components(g)
  return reduce(union, (tree_constructor(g[vs]) for vs in component_vertices))
end

#Given an undirected graph g with vertex set V, build a set of forests (each with vertex set V) which covers all edges in g
# (see https://en.wikipedia.org/wiki/Arboricity) We do not find the minimum but our tests show this algorithm performs well
function build_forest_cover(
  g::AbstractNamedGraph;
  tree_constructor=g ->
    undirected_graph(bfs_tree(g, first(keys(sort(eccentricities(g); rev=true))))),
)
  @assert !NamedGraphs.is_directed(g)
  edges_collected = edgetype(g)[]
  remaining_edges = edges(g)
  forests = NamedGraph[]
  while !isempty(remaining_edges)
    g_reduced = rem_edges(g, edges_collected)
    g_reduced_spanning_forest = spanning_forest(g_reduced; tree_constructor)
    push!(edges_collected, edges(g_reduced_spanning_forest)...)
    push!(forests, g_reduced_spanning_forest)
    setdiff!(remaining_edges, edges(g_reduced_spanning_forest))
  end

  return forests
end
