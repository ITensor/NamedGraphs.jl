using Graphs
using NamedGraphs
using MultiDimDictionaries

parent_graph = grid((2, 2))
vertices = [
  ("X", 1),
  ("X", 2),
  ("Y", 1),
  ("Y", 2),
]

g = MultiDimGraph(parent_graph, vertices)

@show has_vertex(g, "X", 1)
@show has_edge(g, ("X", 1) => ("X", 2))
@show !has_edge(g, ("X", 2) => ("Y", 1))
@show has_edge(g, ("X", 2) => ("Y", 2))

g_sub = g[[("X", 1)]]

@show has_vertex(g_sub, "X", 1)
@show !has_vertex(g_sub, "X", 2)
@show !has_vertex(g_sub, "Y", 1)
@show !has_vertex(g_sub, "Y", 2)

g_sub = g[[("X", 1), ("X", 2)]]

@show has_vertex(g_sub, "X", 1)
@show has_vertex(g_sub, "X", 2)
@show !has_vertex(g_sub, "Y", 1)
@show !has_vertex(g_sub, "Y", 2)

g_sub = g["X", :]

@show has_vertex(g_sub, "X", 1)
@show has_vertex(g_sub, "X", 2)
@show !has_vertex(g_sub, "Y", 1)
@show !has_vertex(g_sub, "Y", 2)

g_sub = g[:, 2]

@show !has_vertex(g_sub, "X", 1)
@show has_vertex(g_sub, "X", 2)
@show !has_vertex(g_sub, "Y", 1)
@show has_vertex(g_sub, "Y", 2)
