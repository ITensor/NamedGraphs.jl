using Dictionaries: Dictionary
using Graphs: Graphs, dijkstra_shortest_paths, weights

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
  return NamedDijkstraState{keytype(parents),eltype(dists)}(
    parents,
    dists,
    convert.(Vector{eltype(parents)}, predecessors),
    pathcounts,
    convert(Vector{eltype(parents)}, closest_vertices),
  )
end

function one_based_path_state_to_path_state(
  graph::AbstractNamedGraph, one_based_path_state::Graphs.DijkstraState
)
  one_based_path_state_parents = map(eachindex(one_based_path_state.parents)) do i
    pᵢ = one_based_path_state.parents[i]
    return iszero(pᵢ) ? i : pᵢ
  end
  # Works around issue in this `Dictionary` constructor:
  # https://github.com/andyferris/Dictionaries.jl/blob/v0.4.1/src/Dictionary.jl#L139-L145
  # when `inds` has holes. This removes the holes.
  # TODO: Raise an issue with `Dictionaries.jl`.
  ## graph_vertices = Indices(collect(vertices(graph)))
  # This makes the vertices ordered according to the parent vertices.
  graph_vertices = map(v -> one_based_vertex_to_vertex(graph, v), one_based_vertices(graph))
  return NamedDijkstraState(
    Dictionary(
      graph_vertices,
      map(v -> one_based_vertex_to_vertex(graph, v), one_based_path_state_parents),
    ),
    Dictionary(graph_vertices, one_based_path_state.dists),
    map(
      x -> map(v -> one_based_vertex_to_vertex(graph, v), x),
      one_based_path_state.predecessors,
    ),
    Dictionary(graph_vertices, one_based_path_state.pathcounts),
    map(v -> one_based_vertex_to_vertex(graph, v), one_based_path_state.closest_vertices),
  )
end

function namedgraph_dijkstra_shortest_paths(
  graph::AbstractNamedGraph,
  srcs,
  distmx=weights(graph);
  allpaths=false,
  trackvertices=false,
)
  one_based_path_state = dijkstra_shortest_paths(
    one_based_graph(graph),
    map(v -> vertex_to_one_based_vertex(graph, v), srcs),
    dist_matrix_to_one_based_dist_matrix(graph, distmx);
    allpaths,
    trackvertices,
  )
  return one_based_path_state_to_path_state(graph, one_based_path_state)
end

function Graphs.dijkstra_shortest_paths(
  graph::AbstractNamedGraph, srcs, distmx=weights(graph); kwargs...
)
  return namedgraph_dijkstra_shortest_paths(graph, srcs, distmx; kwargs...)
end

# Fix ambiguity error with `AbstractGraph` version
function Graphs.dijkstra_shortest_paths(
  graph::AbstractNamedGraph,
  srcs::Vector{<:Integer},
  distmx::AbstractMatrix{<:Real}=weights(graph);
  kwargs...,
)
  return namedgraph_dijkstra_shortest_paths(graph, srcs, distmx; kwargs...)
end

function Graphs.dijkstra_shortest_paths(
  graph::AbstractNamedGraph, vertex::Integer, distmx::AbstractMatrix; kwargs...
)
  return namedgraph_dijkstra_shortest_paths(graph, [vertex], distmx; kwargs...)
end

for f in [
  :(Graphs.bellman_ford_shortest_paths),
  :(Graphs.desopo_pape_shortest_paths),
  :(Graphs.floyd_warshall_shortest_paths),
  :(Graphs.johnson_shortest_paths),
  :(Graphs.yen_k_shortest_paths),
]
  @eval begin
    function $f(graph::AbstractNamedGraph, args...; kwargs...)
      return not_implemented()
    end
  end
end
