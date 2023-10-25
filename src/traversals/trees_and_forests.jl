default_root_vertex(g) = last(findmax(eccentricities(g)))

function spanning_tree(
  g::AbstractNamedGraph; root_vertex=default_root_vertex(g), alg::String="BFS"
)
  @assert !NamedGraphs.is_directed(g)
  if alg == "BFS"
    return undirected_graph(bfs_tree(g, root_vertex))
  elseif alg == "RandomBFS"
    return undirected_graph(random_bfs_tree(g, root_vertex))
  elseif alg == "DFS"
    return undirected_graph(dfs_tree(g, root_vertex))
  else
    error("Algorithm not current supported")
  end
end

#Given a graph, split it into its connected components, construct a spanning tree over each of them
# and take the union.
function spanning_forest(
  g::AbstractNamedGraph; spanning_tree_function=g -> spanning_tree(g)
)
  return reduce(union, (spanning_tree_function(g[vs]) for vs in connected_components(g)))
end

#Given an undirected graph g with vertex set V, build a set of forests (each with vertex set V) which covers all edges in g
# (see https://en.wikipedia.org/wiki/Arboricity) We do not find the minimum but our tests show this algorithm performs well
function build_forest_cover(
  g::AbstractNamedGraph; spanning_tree_function=g -> spanning_tree(g)
)
  edges_collected = edgetype(g)[]
  remaining_edges = edges(g)
  forests = NamedGraph[]
  while !isempty(remaining_edges)
    g_reduced = rem_edges(g, edges_collected)
    g_reduced_spanning_forest = spanning_forest(g_reduced; spanning_tree_function)
    push!(edges_collected, edges(g_reduced_spanning_forest)...)
    push!(forests, g_reduced_spanning_forest)
    setdiff!(remaining_edges, edges(g_reduced_spanning_forest))
  end

  return forests
end
