using Graphs
using NamedGraphs

parent_graph = grid((4,))
vertices = ["A", "B", "C", "D"]
g = NamedDimGraph(parent_graph, vertices)

@show has_vertex(g, "A")
@show !has_vertex(g, "E")
@show has_edge(g, "A" => "B")
@show !has_edge(g, "A" => "C")

g_sub = g[["A"]]

@show has_vertex(g_sub, "A")
@show !has_vertex(g_sub, "B")
@show !has_vertex(g_sub, "C")
@show !has_vertex(g_sub, "D")

g_sub = g[["A", "B"]]

@show has_vertex(g_sub, "A")
@show has_vertex(g_sub, "B")
@show !has_vertex(g_sub, "C")
@show !has_vertex(g_sub, "D")

@show has_edge(g_sub, "A" => "B")

g_sub = g[:]

@show has_vertex(g_sub, "A")
@show has_vertex(g_sub, "B")
@show has_vertex(g_sub, "C")
@show has_vertex(g_sub, "D")

# Error: vertex names are the same
# g_vcat = [g; g]

g_hcat = [g;; g]

@show nv(g_hcat) == 8
@show ne(g_hcat) == 6

@show has_vertex(g_hcat, "A", 1)

g_union = g ⊔ g

@show nv(g_union) == 8
@show ne(g_union) == 6

@show has_vertex(g_union, 1, "A")
