using Graphs: grid
using NamedGraphs.GraphsExtensions: subgraph, ⊔
using NamedGraphs: NamedGraph

g1 = NamedGraph(grid((2, 2)), Tuple.(CartesianIndices((2, 2))))
g2 = NamedGraph(grid((2, 2)), Tuple.(CartesianIndices((2, 2))))
g = ⊔("X" => g1, "Y" => g2)

@show g1
@show g2
@show g
@show subgraph(v -> v[1] == "X", g)
@show subgraph(v -> v[1] == "Y", g)
