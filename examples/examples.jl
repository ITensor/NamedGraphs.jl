using Graphs
using NamedGraphs

g = set_vertices(grid((4,)), ["A", "B", "C", "D"])
@show g
@show g[["A", "B"]]
@show has_edge(g, "A" => "B")
@show add_edge!(g, "A" => "C")
@show has_edge(g, "A" => "C")
