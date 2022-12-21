"""
    struct NamedDijkstraState{V,T}

An [`AbstractPathState`](@ref) designed for Dijkstra shortest-paths calculations.
"""
struct NamedDijkstraState{V,T<:Real} <: Graphs.AbstractPathState
  parents::Dictionary{V,V}
  dists::Dictionary{V,T}
  predecessors::Vector{Vector{V}}
  pathcounts::Dictionary{V,Float64}
  closest_vertices::Vector{V}
end

function NamedDijkstraState(parents, dists, predecessors, pathcounts, closest_vertices)
  return NamedDijkstraState{eltype(dists),eltype(parents)}(
    parents,
    dists,
    convert.(Vector{eltype(parents)}, predecessors),
    pathcounts,
    convert(Vector{eltype(parents)}, closest_vertices),
  )
end

function parent_path_state_to_path_state(
  graph::AbstractNamedGraph,
  parent_path_state::Graphs.DijkstraState,
)
  parent_path_state_parents = map(eachindex(parent_path_state.parents)) do i
    pᵢ = parent_path_state.parents[i]
    return iszero(pᵢ) ? i : pᵢ
  end
  return NamedDijkstraState(
    Dictionary(vertices(graph), parent_vertices_to_vertices(graph, parent_path_state_parents)),
    Dictionary(vertices(graph), parent_path_state.dists),
    map(x -> parent_vertices_to_vertices(graph, x), parent_path_state.predecessors),
    Dictionary(vertices(graph), parent_path_state.pathcounts),
    parent_vertices_to_vertices(graph, parent_path_state.closest_vertices),
  )
end

function _dijkstra_shortest_paths(
  graph::AbstractNamedGraph,
  srcs,
  distmx=weights(graph);
  allpaths=false,
  trackvertices=false,
)
  parent_path_state = dijkstra_shortest_paths(
    parent_graph(graph),
    vertices_to_parent_vertices(graph, srcs),
    dist_matrix_to_parent_dist_matrix(graph, distmx);
    allpaths,
    trackvertices,
  )
  return parent_path_state_to_path_state(graph, parent_path_state)
end

function dijkstra_shortest_paths(
  graph::AbstractNamedGraph,
  srcs,
  distmx=weights(graph);
  kwargs...,
)
  return _dijkstra_shortest_paths(graph, srcs, distmx; kwargs...)
end

function dijkstra_shortest_paths(
  graph::AbstractNamedGraph,
  vertex::Integer,
  distmx::AbstractMatrix;
  kwargs...,
)
  return _dijkstra_shortest_paths(graph, [vertex], distmx; kwargs...)
end

for f in [
  :bellman_ford_shortest_paths,
  :desopo_pape_shortest_paths,
  :floyd_warshall_shortest_paths,
  :johnson_shortest_paths,
  :yen_k_shortest_paths,
]
  @eval begin
    function $f(graph::AbstractNamedGraph, args...; kwargs...)
      return not_implemented()
    end
  end
end
