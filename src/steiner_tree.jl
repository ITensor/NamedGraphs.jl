using Graphs: Graphs, IsDirected, nv, steiner_tree
using SimpleTraits: SimpleTraits, Not, @traitfn

@traitfn function Graphs.steiner_tree(
  g::AbstractNamedGraph::(!IsDirected), term_vert, distmx=weights(g)
)
  ordinal_tree = steiner_tree(
    ordinal_graph(g),
    map(v -> vertex_to_ordinal_vertex(g, v), term_vert),
    dist_matrix_to_ordinal_dist_matrix(g, distmx),
  )
  return typeof(g)(
    ordinal_tree, map(v -> ordinal_vertex_to_vertex(g, v), vertices(ordinal_tree))
  )
end
