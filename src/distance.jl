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

# Mirrors the `AbstractGraph` signature in Graphs.jl so the wrapper above is
# not ambiguous with it. The bound matches Graphs.jl exactly: widening
# `<:Number` to `<:Real` here would leave `Complex` distance matrices
# ambiguous.
function Graphs.eccentricity(
        graph::AbstractNamedGraph,
        vertex::Integer,
        distmx::AbstractMatrix{<:Number} = weights(graph)
    )
    return namedgraph_eccentricity(graph, vertex, distmx)
end

function Graphs.eccentricity(graph::AbstractNamedGraph, vertex, distmx::AbstractMatrix)
    return namedgraph_eccentricity(graph, vertex, distmx)
end

# Graphs.jl reads a lone matrix here as the distance matrix, and returns the
# eccentricity of every vertex. It can do that because its vertices are always
# integers, so the type of this argument is free to carry another meaning. A
# named graph's vertices are arbitrary and may themselves be matrices, so the
# argument stays a vertex and this is the eccentricity of the vertex `vertex`.
# Use `eccentricities` for every vertex. Without this method the call is
# ambiguous with the `AbstractGraph` version.
function Graphs.eccentricity(graph::AbstractNamedGraph, vertex::AbstractMatrix)
    return namedgraph_eccentricity(graph, vertex, weights(graph))
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
