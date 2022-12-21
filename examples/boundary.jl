using NamedGraphs
using Graphs

g = named_grid((5, 5))
subgraph_vertices = [
  (2, 2),
  (2, 3),
  (2, 4),
  (3, 2),
  (3, 3),
  (3, 4),
  (4, 2),
  (4, 3),
  (4, 4),
]
vs = @show boundary_vertices(g, subgraph_vertices)
vs = @show inner_boundary_vertices(g, subgraph_vertices)
vs = @show outer_boundary_vertices(g, subgraph_vertices)
es = @show boundary_edges(g, subgraph_vertices)
