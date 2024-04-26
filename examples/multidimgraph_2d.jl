using Graphs: grid, has_edge, has_vertex, nv
using NamedGraphs: NamedGraph
using NamedGraphs.GraphsExtensions: ⊔, subgraph

position_graph = grid((2, 2))
vs = [("X", 1), ("X", 2), ("Y", 1), ("Y", 2)]

g = NamedGraph(position_graph, vs)

@show has_vertex(g, ("X", 1))
@show has_edge(g, ("X", 1) => ("X", 2))
@show !has_edge(g, ("X", 2) => ("Y", 1))
@show has_edge(g, ("X", 2) => ("Y", 2))

g_sub = subgraph(g, [("X", 1)])

@show has_vertex(g_sub, ("X", 1))
@show !has_vertex(g_sub, ("X", 2))
@show !has_vertex(g_sub, ("Y", 1))
@show !has_vertex(g_sub, ("Y", 2))

g_sub = subgraph(g, [("X", 1), ("X", 2)])

@show has_vertex(g_sub, ("X", 1))
@show has_vertex(g_sub, ("X", 2))
@show !has_vertex(g_sub, ("Y", 1))
@show !has_vertex(g_sub, ("Y", 2))

# g_sub = g["X", :]
g_sub = subgraph(v -> v[1] == "X", g)

@show has_vertex(g_sub, ("X", 1))
@show has_vertex(g_sub, ("X", 2))
@show !has_vertex(g_sub, ("Y", 1))
@show !has_vertex(g_sub, ("Y", 2))

# g_sub = g[:, 2]
g_sub = subgraph(v -> v[2] == 2, g)

@show !has_vertex(g_sub, ("X", 1))
@show has_vertex(g_sub, ("X", 2))
@show !has_vertex(g_sub, ("Y", 1))
@show has_vertex(g_sub, ("Y", 2))

position_graph = grid((2, 2))
g1 = NamedGraph(position_graph, Tuple.(CartesianIndices((2, 2))))
g2 = NamedGraph(position_graph, Tuple.(CartesianIndices((2, 2))))

g_disjoint_union = g1 ⊔ g2

@show nv(g_disjoint_union) == 8

## g_vcat = [g1; g2]
## 
## @show nv(g_vcat) == 8
## 
## g_hcat = [g1;; g2]
## 
## @show nv(g_hcat) == 8
