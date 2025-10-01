using Graphs: path_graph
using NamedGraphs: NamedGraph
using NamedGraphs.GraphsExtensions: mincut_partitions

g = NamedGraph(path_graph(4), ["A", "B", "C", "D"])

part1, part2 = mincut_partitions(g)
@show part1, part2

# Requires `GraphsFlows` to be loaded.
using GraphsFlows: GraphsFlows
part1, part2 = mincut_partitions(g, "A", "D")
@show part1, part2

weights = Dict{Any, Float64}()
weights["A", "B"] = 3.0
weights["B", "C"] = 2.0
weights["C", "D"] = 3.0

part1, part2 = mincut_partitions(g, weights)
@show part1, part2

part1, part2 = mincut_partitions(g, "A", "D", weights)
@show part1, part2
