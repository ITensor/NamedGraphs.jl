module NamedGraphsGraphsFlowsExt
using Graphs: AbstractGraph, IsDirected
using GraphsFlows: GraphsFlows
using NamedGraphs:
  NamedGraphs,
  AbstractNamedGraph,
  DefaultNamedCapacity,
  _symmetrize,
  dist_matrix_to_ordinal_dist_matrix,
  ordinal_graph,
  ordinal_vertex_to_vertex,
  vertex_to_ordinal_vertex
using NamedGraphs.GraphsExtensions: GraphsExtensions, directed_graph
using SimpleTraits: SimpleTraits, @traitfn

@traitfn function NamedGraphs.dist_matrix_to_ordinal_dist_matrix(
  graph::AbstractNamedGraph::IsDirected, dist_matrix::DefaultNamedCapacity
)
  return GraphsFlows.DefaultCapacity(graph)
end

@traitfn function GraphsFlows.mincut(
  graph::AbstractNamedGraph::IsDirected,
  source,
  target,
  capacity_matrix=DefaultNamedCapacity(graph),
  algorithm::GraphsFlows.AbstractFlowAlgorithm=GraphsFlows.PushRelabelAlgorithm(),
)
  ordinal_part1, ordinal_part2, flow = GraphsFlows.mincut(
    directed_graph(ordinal_graph(graph)),
    vertex_to_ordinal_vertex(graph, source),
    vertex_to_ordinal_vertex(graph, target),
    dist_matrix_to_ordinal_dist_matrix(graph, capacity_matrix),
    algorithm,
  )
  (part1, part2) = map((ordinal_part1, ordinal_part2)) do ordinal_part
    return map(v -> ordinal_vertex_to_vertex(graph, v), ordinal_part)
  end
  return (part1, part2, flow)
end

@traitfn function GraphsFlows.mincut(
  graph::AbstractNamedGraph::(!IsDirected),
  source,
  target,
  capacity_matrix=DefaultNamedCapacity(graph),
  algorithm::GraphsFlows.AbstractFlowAlgorithm=GraphsFlows.PushRelabelAlgorithm(),
)
  return GraphsFlows.mincut(
    directed_graph(graph), source, target, _symmetrize(capacity_matrix), algorithm
  )
end

function GraphsExtensions.mincut_partitions(
  graph::AbstractGraph,
  source,
  target,
  capacity_matrix=DefaultNamedCapacity(graph),
  algorithm::GraphsFlows.AbstractFlowAlgorithm=GraphsFlows.PushRelabelAlgorithm(),
)
  part1, part2, flow = GraphsFlows.mincut(graph, source, target, capacity_matrix, algorithm)
  return part1, part2
end
end
