using Graphs: Graphs, IsDirected, nv, steiner_tree
using SimpleTraits: SimpleTraits, Not, @traitfn

@traitfn function Graphs.steiner_tree(
  g::AbstractNamedGraph::(!IsDirected), term_vert, distmx=weights(g)
)
  one_based_tree = steiner_tree(
    one_based_graph(g),
    map(v -> vertex_to_one_based_vertex(g, v), term_vert),
    dist_matrix_to_one_based_dist_matrix(g, distmx),
  )
  return typeof(g)(
    one_based_tree, map(v -> one_based_vertex_to_vertex(g, v), vertices(one_based_tree))
  )
end
