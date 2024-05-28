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
  named_st = typeof(g)(
    position_tree, map(v -> ordered_vertices(g)[v], vertices(position_tree))
  )
  # Detect and remove vertices of degree zero
  zero_verts = filter(v -> degree(named_st, v) == 0, vertices(named_st))
  for v in zero_verts
    rem_vertex!(named_st, v)
  end
  return named_st
end
