using Graphs: AbstractGraph, neighborhood_dists

function vertices_at_distance(g::AbstractGraph, vertex, distance::Int)
    vertices_and_distances = neighborhood_dists(g, vertex, distance)
    return map(first, filter(==(distance) ∘ last, vertices_and_distances))
end

next_nearest_neighbors(g::AbstractGraph, v) = vertices_at_distance(g, v, 2)
