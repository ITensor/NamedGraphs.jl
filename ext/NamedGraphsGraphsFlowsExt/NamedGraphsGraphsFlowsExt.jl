module NamedGraphsGraphsFlowsExt
using Graphs: AbstractGraph, IsDirected
using GraphsFlows: GraphsFlows
using NamedGraphs.GraphsExtensions: GraphsExtensions, directed_graph
using NamedGraphs: NamedGraphs, AbstractNamedGraph, DefaultNamedCapacity, _symmetrize,
    coded_graph, coded_vertex, decoded_vertex, dist_matrix_to_coded_dist_matrix
using SimpleTraits: SimpleTraits, @traitfn

@traitfn function NamedGraphs.dist_matrix_to_coded_dist_matrix(
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
    coded_part1, coded_part2, flow = GraphsFlows.mincut(
        directed_graph(coded_graph(graph)),
        coded_vertex(graph, source),
        coded_vertex(graph, target),
        dist_matrix_to_coded_dist_matrix(graph, capacity_matrix),
        algorithm
    )
    (part1, part2) = map((coded_part1, coded_part2)) do coded_part
        return map(decoded_vertex(graph), coded_part)
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
