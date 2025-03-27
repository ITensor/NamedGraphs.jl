using Combinatorics: powerset
using Graphs: Graphs, is_tree, simplecycles_limited_length
using NamedGraphs.GraphsExtensions: add_edges, disjoint_union, edge_subgraph
using SplitApplyCombine: group

function Graphs.simplecycles_limited_length(g::AbstractNamedGraph, max_cycle_size::Int64)
  vs = collect(vertices(g))
  cycles = simplecycles_limited_length(position_graph(g), max_cycle_size)
  cycles = [[vs[i] for i in cycle] for cycle in cycles]
  return cycles
end

function unique_simplecycles_limited_length(g::AbstractNamedGraph, max_cycle_size)
  cycles = simplecycles_limited_length(g, max_cycle_size)

  #Filter out length 2 cycles and non-unique cycles
  cycles = filter(cycle -> length(cycle) > 2, cycles)
  cycles = group(cycle -> Set(cycle), cycles)
  cycles = first.(collect(values(cycles)))

  return cycles
end

function cycle_to_path(g::AbstractNamedGraph, cycle::Vector)
  es = [NamedEdge(cycle[i] => cycle[i + 1]) for i in 1:(length(cycle) - 1)]
  final_edge = NamedEdge(first(cycle) => last(cycle))
  return vcat(es, final_edge)
end

function unique_cyclesubgraphs_limited_length(g::AbstractNamedGraph, max_cycle_size::Int64)
  cycles = unique_simplecycles_limited_length(g, max_cycle_size)
  paths = cycle_to_path.((g,), cycles)
  return edge_subgraph.((g,), paths)
end

"""
Enumerate all unqiue, connected edgesubgraphs without any leaf vertices (degree 1) and with Nedges <= max_number_of_edges
"""
function edgeinduced_subgraphs_no_leaves(g::AbstractNamedGraph, max_number_of_edges::Int64)
  edge_subgraphs = unique_cyclesubgraphs_limited_length(g, max_number_of_edges)
  isempty(edge_subgraphs) && return []

  #Take powerset, but don't exceed max_number of edges and remove disconnected components
  min_loop_size = minimum(length.(edges.(edge_subgraphs)))
  max_genus = round(Int64, ceil(max_number_of_edges / min_loop_size))
  subgraph_components = collect(powerset(edge_subgraphs, 1, max_genus))

  edge_subgraphs = []
  for sc in subgraph_components
    g = reduce(union, sc)
    if is_connected(g) && ne(g) <= max_number_of_edges && g ∉ edge_subgraphs
      push!(edge_subgraphs, g)
    end
  end

  return edge_subgraphs
end
