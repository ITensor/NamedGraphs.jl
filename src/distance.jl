function _eccentricity(graph::AbstractNamedGraph, vertex, distmx)
  e = maximum(dijkstra_shortest_paths(graph, [vertex], distmx).dists)
  e == typemax(e) && @warn("Infinite path length detected for vertex $vertex")
  return e
end

function eccentricity(graph::AbstractNamedGraph, vertex, distmx=weights(graph))
  return _eccentricity(graph, vertex, distmx)
end

# Fix for ambiguity error with `AbstractGraph`
function eccentricity(
  graph::AbstractNamedGraph, vertex::Integer, distmx::AbstractMatrix{<:Real}
)
  return _eccentricity(graph, vertex, distmx)
end

function eccentricity(graph::AbstractNamedGraph, vertex, distmx::AbstractMatrix)
  return _eccentricity(graph, vertex, distmx)
end

# function eccentricity(graph::AbstractNamedGraph, ::AbstractMatrix)

eccentricities(graph::AbstractGraph) = eccentricities(graph, Indices(vertices(graph)))

function eccentricities(graph::AbstractGraph, vs, distmx=weights(graph))
  return map(vertex -> eccentricity(graph, vertex, distmx), vs)
end

function _center(graph::AbstractNamedGraph, distmx)
  # TODO: Why does this return the parent vertices?
  return parent_vertices_to_vertices(
    graph, center(eccentricities(graph, vertices(graph), distmx))
  )
end

function center(graph::AbstractNamedGraph, distmx=weights(graph))
  return _center(graph, distmx)
end

# Fix for ambiguity error with `AbstractGraph`
function center(graph::AbstractNamedGraph, distmx::AbstractMatrix)
  return _center(graph, distmx)
end

function _radius(graph::AbstractNamedGraph, distmx)
  return radius(eccentricities(graph, vertices(graph), distmx))
end

function radius(graph::AbstractNamedGraph, distmx=weights(graph))
  return _radius(graph, distmx)
end

# Fix for ambiguity error with `AbstractGraph`
function radius(graph::AbstractNamedGraph, distmx::AbstractMatrix)
  return _radius(graph, distmx)
end

function _diameter(graph::AbstractNamedGraph, distmx)
  return diameter(eccentricities(graph, vertices(graph), distmx))
end

function diameter(graph::AbstractNamedGraph, distmx=weights(graph))
  return _diameter(graph, distmx)
end

# Fix for ambiguity error with `AbstractGraph`
function diameter(graph::AbstractNamedGraph, distmx::AbstractMatrix)
  return _diameter(graph, distmx)
end

function _periphery(graph::AbstractNamedGraph, distmx)
  # TODO: Why does this return the parent vertices?
  return parent_vertices_to_vertices(
    graph, periphery(eccentricities(graph, vertices(graph), distmx))
  )
end

function periphery(graph::AbstractNamedGraph, distmx=weights(graph))
  return _periphery(graph, distmx)
end

# Fix for ambiguity error with `AbstractGraph`
function periphery(graph::AbstractNamedGraph, distmx::AbstractMatrix)
  return _periphery(graph, distmx)
end
