using Graphs
using NamedGraphs

g = NamedGraph(grid((4,)), ["A", "B", "C", "D"])

@show has_vertex(g, "A")
@show has_vertex(g, "B")
@show has_vertex(g, "C")
@show has_vertex(g, "D")

@show has_edge(g, "A" => "B")

add_edge!(g, "A" => "C")

@show has_edge(g, "A" => "C")
@show issetequal(neighbors(g, "A"), ["B", "C"])
@show issetequal(neighbors(g, "B"), ["A", "C"])

g_sub = g[["A", "B"]]

@show has_vertex(g_sub, "A")
@show has_vertex(g_sub, "B")
@show !has_vertex(g_sub, "C")
@show !has_vertex(g_sub, "D")
@show has_edge(g_sub, "A" => "B")
