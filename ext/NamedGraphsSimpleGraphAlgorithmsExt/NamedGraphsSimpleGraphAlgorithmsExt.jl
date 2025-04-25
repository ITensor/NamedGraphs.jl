module NamedGraphsSimpleGraphAlgorithmsExt
using Graphs: AbstractGraph, edgetype
using NamedGraphs: position_graph, vertices
using NamedGraphs.GraphsExtensions: GraphsExtensions
using SimpleGraphAlgorithms: SimpleGraphAlgorithms
using SimpleGraphConverter: UG

function SimpleGraphAlgorithms.edge_color(g::AbstractGraph, k::Int64)
  pg, vs = position_graph(g), collect(vertices(g))
  ec_dict = SimpleGraphAlgorithms.edge_color(UG(pg), k)
  # returns k vectors of edges which each contain the colored/commuting edges
  return [
    [edgetype(g)(vs[first(first(e))], vs[last(first(e))]) for e in ec_dict if last(e) == i]
    for i in 1:k
  ]
end
end
