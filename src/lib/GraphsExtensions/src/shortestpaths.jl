using Graphs: Graphs, dijkstra_shortest_paths, edgetype, weights

function dijkstra_parents(graph::AbstractGraph, vertex, distmx=weights(graph))
  return dijkstra_shortest_paths(
    graph, [vertex], distmx; allpaths=false, trackvertices=false
  ).parents
end

function dijkstra_mst(graph::AbstractGraph, vertex, distmx=weights(graph))
  parents =
    dijkstra_shortest_paths(graph, [vertex], distmx; allpaths=false, trackvertices=false).parents
  mst = Vector{edgetype(graph)}()
  for src in eachindex(parents)
    dst = parents[src]
    if src ≠ dst
      push!(mst, edgetype(graph)(src, dst))
    end
  end
  return mst
end

function dijkstra_tree(graph::AbstractGraph, vertex, distmx=weights(graph))
  return Graphs.tree(graph, dijkstra_parents(graph, vertex, distmx))
end
