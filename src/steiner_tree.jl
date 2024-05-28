using Graphs: Graphs, IsDirected, nv, steiner_tree
using SimpleTraits: SimpleTraits, Not, @traitfn

@traitfn function Graphs.steiner_tree(
  g::AbstractNamedGraph::(!IsDirected), term_vert, distmx=weights(g)
)
  position_tree = steiner_tree(
    position_graph(g),
    map(v -> vertex_positions(g)[v], term_vert),
    dist_matrix_to_position_dist_matrix(g, distmx),
  )
  tree = typeof(g)(position_tree, map(v -> ordered_vertices(g)[v], vertices(position_tree)))
  for v in copy(vertices(tree))
    iszero(degree(tree, v)) && rem_vertex!(tree, v)
  end
  return tree
end
