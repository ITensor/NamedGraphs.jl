@traitfn function steiner_tree(
  g::AbstractNamedGraph::(!IsDirected), term_vert, distmx=weights(g)
)
  parent_tree = steiner_tree(
    parent_graph(g),
    vertices_to_parent_vertices(g, term_vert),
    dist_matrix_to_parent_dist_matrix(g, distmx),
  )
  return typeof(g)(parent_tree, vertices(g)[1:nv(parent_tree)])
end
