using .GraphsExtensions: eccentricities
using Graphs: Graphs, dijkstra_shortest_paths, weights

function namedgraph_eccentricity(graph::AbstractNamedGraph, vertex, distmx)
    e = maximum(dijkstra_shortest_paths(graph, [vertex], distmx).dists)
    e == typemax(e) && @warn("Infinite path length detected for vertex $vertex")
    return e
end

function Graphs.eccentricity(graph::AbstractNamedGraph, vertex, distmx = weights(graph))
    return namedgraph_eccentricity(graph, vertex, distmx)
end

# Fix for ambiguity error with `AbstractGraph`
function Graphs.eccentricity(
        graph::AbstractNamedGraph, vertex::Integer, distmx::AbstractMatrix{<:Real}
    )
    return namedgraph_eccentricity(graph, vertex, distmx)
end

function Graphs.eccentricity(graph::AbstractNamedGraph, vertex, distmx::AbstractMatrix)
    return namedgraph_eccentricity(graph, vertex, distmx)
end

function eccentricities_center(eccentricities)
    rad = eccentricities_radius(eccentricities)
    return filter(x -> eccentricities[x] == rad, keys(eccentricities))
end
function eccentricities_periphery(eccentricities)
    diam = eccentricities_diameter(eccentricities)
    return filter(x -> eccentricities[x] == diam, keys(eccentricities))
end
eccentricities_radius(eccentricities) = minimum(eccentricities)
eccentricities_diameter(eccentricities) = maximum(eccentricities)

function namedgraph_center(graph::AbstractNamedGraph, distmx)
    return eccentricities_center(eccentricities(graph, vertices(graph), distmx))
end

function Graphs.center(graph::AbstractNamedGraph, distmx = weights(graph))
    return namedgraph_center(graph, distmx)
end

# Fix for ambiguity error with `AbstractGraph`
function Graphs.center(graph::AbstractNamedGraph, distmx::AbstractMatrix)
    return namedgraph_center(graph, distmx)
end

function namedgraph_radius(graph::AbstractNamedGraph, distmx)
    return eccentricities_radius(eccentricities(graph, vertices(graph), distmx))
end

function Graphs.radius(graph::AbstractNamedGraph, distmx = weights(graph))
    return namedgraph_radius(graph, distmx)
end

# Fix for ambiguity error with `AbstractGraph`
function Graphs.radius(graph::AbstractNamedGraph, distmx::AbstractMatrix)
    return namedgraph_radius(graph, distmx)
end

function namedgraph_diameter(graph::AbstractNamedGraph, distmx)
    return eccentricities_diameter(eccentricities(graph, vertices(graph), distmx))
end

function Graphs.diameter(graph::AbstractNamedGraph, distmx = weights(graph))
    return namedgraph_diameter(graph, distmx)
end

# Fixes for ambiguity error with `AbstractGraph`
function Graphs.diameter(graph::AbstractNamedGraph, distmx::AbstractMatrix)
    return namedgraph_diameter(graph, distmx)
end
function Graphs.diameter(graph::AbstractNamedGraph, distmx::Graphs.DefaultDistance)
    return namedgraph_diameter(graph, distmx)
end

function namedgraph_periphery(graph::AbstractNamedGraph, distmx)
    return eccentricities_periphery(eccentricities(graph, vertices(graph), distmx))
end

function Graphs.periphery(graph::AbstractNamedGraph, distmx = weights(graph))
    return namedgraph_periphery(graph, distmx)
end

# Fix for ambiguity error with `AbstractGraph`
function Graphs.periphery(graph::AbstractNamedGraph, distmx::AbstractMatrix)
    return namedgraph_periphery(graph, distmx)
end
