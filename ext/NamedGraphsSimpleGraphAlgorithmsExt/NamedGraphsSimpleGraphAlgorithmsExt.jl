module NamedGraphsSimpleGraphAlgorithmsExt
using Graphs: edgetype
using NamedGraphs.GraphsExtensions: GraphsExtensions
using NamedGraphs: AbstractNamedGraph, coded_graph, decoded_vertex
using SimpleGraphAlgorithms: SimpleGraphAlgorithms
using SimpleGraphConverter: UndirectedGraph

function SimpleGraphAlgorithms.edge_color(g::AbstractNamedGraph, k::Int64)
    ec_dict = SimpleGraphAlgorithms.edge_color(UndirectedGraph(coded_graph(g)), k)
    # returns k vectors of edges which each contain the colored/commuting edges
    return [
        [
                edgetype(g)(
                    decoded_vertex(g, first(first(e))), decoded_vertex(g, last(first(e)))
                ) for
                e in ec_dict if last(e) == i
            ]
            for i in 1:k
    ]
end
end
