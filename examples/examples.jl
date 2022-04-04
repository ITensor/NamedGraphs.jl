using Graphs
using NamedGraphs

using MultiDimDictionaries

Base.convert(::Type{<:CartesianKey}, t::Tuple) = CartesianKey(t...)

g = NamedGraph(grid((4,)), ["A", "B", "C", "D"])
@show g
@show has_edge(g, "A" => "B")
@show add_edge!(g, "A" => "C")
@show has_edge(g, "A" => "C")
@show neighbors(g, "A")
@show neighbors(g, "B")
@show g[["A", "B"]]

## g2 = set_vertices(grid((2, 2)), [CartesianKey("X", "X"), CartesianKey("X", "Y"), CartesianKey("Y", "X"), CartesianKey("Y", "Y")])
## 
## # XXX: Requires `convert` method for Tuple to CartesianKey
## @show has_vertex(g2, ("X", "X"))
## 
## # XXX: Requires constructor of CartesianKey from Tuple
## # @show has_edge(g2, ("X", "X") => ("X", "Y"))
## 
## @show has_edge(g2, CartesianKey("X", "X") => CartesianKey("X", "Y"))
## 
## @show g2[[CartesianKey("X", "X")]]
## @show g2[[CartesianKey("X", "X"), CartesianKey("X", "Y")]]

