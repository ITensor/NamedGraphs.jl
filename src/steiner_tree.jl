using Graphs: Graphs, IsDirected, nv, steiner_tree
using SimpleTraits: SimpleTraits, Not, @traitfn

@traitfn function Graphs.steiner_tree(
  g::AbstractNamedGraph::(!IsDirected), term_vert, distmx=weights(g)
)
  parent_tree = steiner_tree(
    parent_graph(g),
    vertices_to_parent_vertices(g, term_vert),
    dist_matrix_to_parent_dist_matrix(g, distmx),
  )
  return typeof(g)(parent_tree, parent_vertices_to_vertices(g, Base.OneTo(nv(parent_tree))))
end
