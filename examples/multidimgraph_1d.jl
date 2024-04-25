using Graphs: grid, has_edge, has_vertex, ne, nv
using NamedGraphs: NamedGraph
using NamedGraphs.GraphsExtensions: ⊔, subgraph

one_based_graph = grid((4,))
vs = ["A", "B", "C", "D"]
g = NamedGraph(one_based_graph, vs)

@show has_vertex(g, "A")
@show !has_vertex(g, "E")
@show has_edge(g, "A" => "B")
@show !has_edge(g, "A" => "C")

g_sub = subgraph(g, ["A"])

@show has_vertex(g_sub, "A")
@show !has_vertex(g_sub, "B")
@show !has_vertex(g_sub, "C")
@show !has_vertex(g_sub, "D")

g_sub = subgraph(g, ["A", "B"])

@show has_vertex(g_sub, "A")
@show has_vertex(g_sub, "B")
@show !has_vertex(g_sub, "C")
@show !has_vertex(g_sub, "D")

@show has_edge(g_sub, "A" => "B")

g_sub = subgraph(Returns(true), g)

@show has_vertex(g_sub, "A")
@show has_vertex(g_sub, "B")
@show has_vertex(g_sub, "C")
@show has_vertex(g_sub, "D")

g_union = g ⊔ g

@show nv(g_union) == 8
@show ne(g_union) == 6

@show has_vertex(g_union, ("A", 1))
@show has_vertex(g_union, ("A", 2))

# Error: vertex names are the same
# g_vcat = [g; g]

# TODO: Implement
## g_hcat = [g;; g]
## 
## @show nv(g_hcat) == 8
## @show ne(g_hcat) == 6
## 
## @show has_vertex(g_hcat, ("A", 1))
