module NamedGraphsGraphsFlowsExt
using Graphs: AbstractGraph, IsDirected
using GraphsFlows: GraphsFlows
using NamedGraphs:
  NamedGraphs,
  AbstractNamedGraph,
  DefaultNamedCapacity,
  _symmetrize,
  dist_matrix_to_parent_dist_matrix,
  ordinal_graph,
  parent_vertices_to_vertices,
  vertex_to_parent_vertex
using NamedGraphs.GraphsExtensions: GraphsExtensions, directed_graph
using SimpleTraits: SimpleTraits, @traitfn

@traitfn function NamedGraphs.dist_matrix_to_parent_dist_matrix(
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
  parent_part1, parent_part2, flow = GraphsFlows.mincut(
    directed_graph(ordinal_graph(graph)),
    vertex_to_parent_vertex(graph, source),
    vertex_to_parent_vertex(graph, target),
    dist_matrix_to_parent_dist_matrix(graph, capacity_matrix),
    algorithm,
  )
  part1 = parent_vertices_to_vertices(graph, parent_part1)
  part2 = parent_vertices_to_vertices(graph, parent_part2)
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
