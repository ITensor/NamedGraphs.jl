using Graphs: AbstractGraph, neighborhood

function nth_nearest_neighbors(g::AbstractGraph, v, n::Int)
  isone(n) && return neighborhood(g, v, 1)
  return setdiff(neighborhood(g, v, n), neighborhood(g, v, n - 1))
end

next_nearest_neighbors(g::AbstractGraph, v) = nth_nearest_neighbors(g, v, 2)
