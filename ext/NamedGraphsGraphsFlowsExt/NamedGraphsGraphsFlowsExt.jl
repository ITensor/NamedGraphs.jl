module NamedGraphsGraphsFlowsExt
using Graphs: AbstractGraph, IsDirected
using GraphsFlows: GraphsFlows
using NamedGraphs:
    NamedGraphs,
    AbstractNamedGraph,
    DefaultNamedCapacity,
    _symmetrize,
    dist_matrix_to_position_dist_matrix,
    ordered_vertices,
    position_graph,
    vertex_positions
using NamedGraphs.GraphsExtensions: GraphsExtensions, directed_graph
using SimpleTraits: SimpleTraits, @traitfn

@traitfn function NamedGraphs.dist_matrix_to_position_dist_matrix(
        graph::AbstractNamedGraph::IsDirected, dist_matrix::DefaultNamedCapacity
    )
    return GraphsFlows.DefaultCapacity(graph)
end

@traitfn function GraphsFlows.mincut(
        graph::AbstractNamedGraph::IsDirected,
        source,
        target,
        capacity_matrix = DefaultNamedCapacity(graph),
        algorithm::GraphsFlows.AbstractFlowAlgorithm = GraphsFlows.PushRelabelAlgorithm(),
    )
    position_part1, position_part2, flow = GraphsFlows.mincut(
        directed_graph(position_graph(graph)),
        vertex_positions(graph)[source],
        vertex_positions(graph)[target],
        dist_matrix_to_position_dist_matrix(graph, capacity_matrix),
        algorithm,
    )
    (part1, part2) = map((position_part1, position_part2)) do position_part
        return map(v -> ordered_vertices(graph)[v], position_part)
    end
    return (part1, part2, flow)
end

@traitfn function GraphsFlows.mincut(
        graph::AbstractNamedGraph::(!IsDirected),
        source,
        target,
        capacity_matrix = DefaultNamedCapacity(graph),
        algorithm::GraphsFlows.AbstractFlowAlgorithm = GraphsFlows.PushRelabelAlgorithm(),
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
        algorithm::GraphsFlows.AbstractFlowAlgorithm = GraphsFlows.PushRelabelAlgorithm(),
    )
    part1, part2, flow = GraphsFlows.mincut(graph, source, target, capacity_matrix, algorithm)
    return part1, part2
end
end
