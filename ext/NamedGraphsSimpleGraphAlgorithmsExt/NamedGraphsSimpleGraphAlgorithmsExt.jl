module NamedGraphsSimpleGraphAlgorithmsExt
using Graphs: AbstractGraph, dst, edges, edgetype, src, vertices
using NamedGraphs.GraphsExtensions: GraphsExtensions
using NamedGraphs: AbstractNamedGraph, decode_vertex, encoded_graph
using SimpleGraphAlgorithms: SimpleGraphAlgorithms
using SimpleGraphs: UndirectedGraph, add!

# SimpleGraphAlgorithms is built on SimpleGraphs.jl rather than Graphs.jl,
# so the encoded graph has to be converted to a `SimpleGraphs.UndirectedGraph`.
function to_undirected_graph(graph::AbstractGraph)
    undirected_graph = UndirectedGraph{eltype(graph)}()
    for vertex in vertices(graph)
        add!(undirected_graph, vertex)
    end
    for edge in edges(graph)
        add!(undirected_graph, src(edge), dst(edge))
    end
    return undirected_graph
end

function SimpleGraphAlgorithms.edge_color(g::AbstractNamedGraph, k::Int64)
    ec_dict = SimpleGraphAlgorithms.edge_color(to_undirected_graph(encoded_graph(g)), k)
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
