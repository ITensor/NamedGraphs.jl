module NamedGraphsGraphsFlowsExt
using Graphs: AbstractGraph, IsDirected
using GraphsFlows: GraphsFlows
using NamedGraphs.GraphsExtensions: GraphsExtensions, directed_graph
using NamedGraphs: NamedGraphs, AbstractNamedGraph, DefaultNamedCapacity, _symmetrize,
    decode_vertex, encode_dist_matrix, encode_vertex, encoded_graph
using SimpleTraits: SimpleTraits, @traitfn

@traitfn function NamedGraphs.encode_dist_matrix(
        graph::AbstractNamedGraph::IsDirected, dist_matrix::DefaultNamedCapacity
    )
    return GraphsFlows.DefaultCapacity(graph)
end

@traitfn function GraphsFlows.mincut(
        graph::AbstractNamedGraph::IsDirected,
        source,
        target,
        capacity_matrix = DefaultNamedCapacity(graph),
        algorithm::GraphsFlows.AbstractFlowAlgorithm = GraphsFlows.PushRelabelAlgorithm()
    )
    encoded_part1, encoded_part2, flow = GraphsFlows.mincut(
        directed_graph(encoded_graph(graph)),
        encode_vertex(graph, source),
        encode_vertex(graph, target),
        encode_dist_matrix(graph, capacity_matrix),
        algorithm
    )
    (part1, part2) = map((encoded_part1, encoded_part2)) do encoded_part
        return map(c -> decode_vertex(graph, c), encoded_part)
    end
    return (part1, part2, flow)
end

@traitfn function GraphsFlows.mincut(
        graph::AbstractNamedGraph::(!IsDirected),
        source,
        target,
        capacity_matrix = DefaultNamedCapacity(graph),
        algorithm::GraphsFlows.AbstractFlowAlgorithm = GraphsFlows.PushRelabelAlgorithm()
    )
    return GraphsFlows.mincut(
        directed_graph(graph), source, target, _symmetrize(capacity_matrix), algorithm
    )
end

function GraphsExtensions.mincut_partitions(
        graph::AbstractGraph,
        source,
        target,
        capacity_matrix = DefaultNamedCapacity(graph),
        algorithm::GraphsFlows.AbstractFlowAlgorithm = GraphsFlows.PushRelabelAlgorithm()
    )
    part1, part2, flow =
        GraphsFlows.mincut(graph, source, target, capacity_matrix, algorithm)
    return part1, part2
end
end
