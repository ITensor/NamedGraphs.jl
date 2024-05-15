using Graphs: AbstractGraph, neighborhood_dists

function vertices_at_distance(g::AbstractGraph, vertex, n::Int)
  neighborhood = [first(v) for v in neighborhood_dists(g, vertex, n)]
  closer_neighborhood = [first(v) for v in neighborhood_dists(g, vertex, n - 1)]
  iszero(n) && return neighborhood
  return setdiff(neighborhood, closer_neighborhood)
end

next_nearest_neighbors(g::AbstractGraph, v) = vertices_at_distance(g, v, 2)
