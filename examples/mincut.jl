using NamedGraphs
using GraphsFlows

g = NamedGraph(path_graph(4), ["A", "B", "C", "D"])

part1, part2, flow = GraphsFlows.mincut(g, "A", "D")
@show part1, part2, flow

weights = Dict{Any,Float64}()
weights["A", "B"] = 3.0
weights["B", "C"] = 2.0
weights["C", "D"] = 3.0
part1, part2, flow = GraphsFlows.mincut(g, "A", "D", weights)
@show part1, part2, flow
