module NamedGraphsSimpleGraphAlgorithmsExt
using Graphs: edgetype
using NamedGraphs.GraphsExtensions: GraphsExtensions
using NamedGraphs: AbstractNamedGraph, decode_vertex, encoded_graph
using SimpleGraphAlgorithms: SimpleGraphAlgorithms
using SimpleGraphConverter: UndirectedGraph

function SimpleGraphAlgorithms.edge_color(g::AbstractNamedGraph, k::Int64)
    ec_dict = SimpleGraphAlgorithms.edge_color(UndirectedGraph(encoded_graph(g)), k)
    # returns k vectors of edges which each contain the colored/commuting edges
    return [
        [
                edgetype(g)(
                    decode_vertex(g, first(first(e))), decode_vertex(g, last(first(e)))
                ) for
                e in ec_dict if last(e) == i
            ]
            for i in 1:k
    ]
end
end
