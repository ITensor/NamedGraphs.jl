using Graphs
using NamedGraphs
using MultiDimDictionaries

parent_graph = grid((2, 2))
vertices = [
  CartesianKey("X", "X"),
  CartesianKey("X", "Y"),
  CartesianKey("Y", "X"),
  CartesianKey("Y", "Y"),
]

g = MultiDimGraph(parent_graph, vertices)

@show has_vertex(g, CartesianKey("X", "X"))
@show has_edge(g, CartesianKey("X", "X") => CartesianKey("X", "Y"))

g_sub = g[[CartesianKey("X", "X")]]

@show has_vertex(g_sub, CartesianKey("X", "X"))
@show !has_vertex(g_sub, CartesianKey("X", "Y"))
@show !has_vertex(g_sub, CartesianKey("Y", "X"))
@show !has_vertex(g_sub, CartesianKey("Y", "Y"))

g_sub = g[[CartesianKey("X", "X"), CartesianKey("X", "Y")]]

@show has_vertex(g_sub, CartesianKey("X", "X"))
@show has_vertex(g_sub, CartesianKey("X", "Y"))
@show !has_vertex(g_sub, CartesianKey("Y", "X"))
@show !has_vertex(g_sub, CartesianKey("Y", "Y"))

g_sub = g["X", :]

@show has_vertex(g_sub, CartesianKey("X", "X"))
@show has_vertex(g_sub, CartesianKey("X", "Y"))
@show !has_vertex(g_sub, CartesianKey("Y", "X"))
@show !has_vertex(g_sub, CartesianKey("Y", "Y"))

g_sub = g[:, "Y"]

@show !has_vertex(g_sub, CartesianKey("X", "X"))
@show has_vertex(g_sub, CartesianKey("X", "Y"))
@show !has_vertex(g_sub, CartesianKey("Y", "X"))
@show has_vertex(g_sub, CartesianKey("Y", "Y"))
