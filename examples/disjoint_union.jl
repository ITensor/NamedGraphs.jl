using Graphs
using NamedGraphs

g1 = NamedDimGraph(grid((2, 2)); dims=(2, 2))
g2 = NamedDimGraph(grid((2, 2)); dims=(2, 2))
g = ⊔(g1, g2; new_dim_names=("X", "Y"))

@show g1
@show g2
@show g
@show g["X", :]
@show g["Y", :]
