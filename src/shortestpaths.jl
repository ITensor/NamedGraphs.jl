using Dictionaries: Dictionary
using Graphs: Graphs, dijkstra_shortest_paths, weights

#     struct NamedDijkstraState{V,T}
#
# An `AbstractPathState` designed for Dijkstra shortest-paths calculations.
struct NamedDijkstraState{V, T <: Real} <: Graphs.AbstractPathState
    parents::Dictionary{V, V}
    dists::Dictionary{V, T}
    predecessors::Vector{Vector{V}}
    pathcounts::Dictionary{V, Float64}
    closest_vertices::Vector{V}
end

function NamedDijkstraState(parents, dists, predecessors, pathcounts, closest_vertices)
    return NamedDijkstraState{keytype(parents), eltype(dists)}(
        parents,
        dists,
        convert.(Vector{eltype(parents)}, predecessors),
        pathcounts,
        convert(Vector{eltype(parents)}, closest_vertices)
    )
end

function encoded_path_state_to_path_state(
        graph::AbstractNamedGraph, encoded_path_state::Graphs.DijkstraState
    )
    encoded_path_state_parents = map(eachindex(encoded_path_state.parents)) do i
        pᵢ = encoded_path_state.parents[i]
        return iszero(pᵢ) ? i : pᵢ
    end
    decode(c) = decode_vertex(graph, c)
    # Keys in code order, to align with the code-indexed path state.
    graph_vertices = map(decode, vertices(encoded_graph(graph)))
    return NamedDijkstraState(
        Dictionary(graph_vertices, map(decode, encoded_path_state_parents)),
        Dictionary(graph_vertices, encoded_path_state.dists),
        map(x -> map(decode, x), encoded_path_state.predecessors),
        Dictionary(graph_vertices, encoded_path_state.pathcounts),
        map(decode, encoded_path_state.closest_vertices)
    )
end

function namedgraph_dijkstra_shortest_paths(
        graph::AbstractNamedGraph,
        srcs,
        distmx = weights(graph);
        allpaths = false,
        trackvertices = false,
        maxdist = typemax(eltype(distmx))
    )
    encoded_path_state = dijkstra_shortest_paths(
        encoded_graph(graph),
        map(v -> encode_vertex(graph, v), srcs),
        encode_dist_matrix(graph, distmx);
        allpaths,
        trackvertices,
        maxdist
    )
    return encoded_path_state_to_path_state(graph, encoded_path_state)
end

function Graphs.dijkstra_shortest_paths(
        graph::AbstractNamedGraph, srcs, distmx = weights(graph); kwargs...
    )
    return namedgraph_dijkstra_shortest_paths(graph, srcs, distmx; kwargs...)
end

# Mirror the `AbstractGraph` signatures in Graphs.jl so the wrappers are not
# ambiguous with them. Copy each bound from Graphs.jl rather than picking one:
# they differ between the two methods below, and narrowing `<:Number` to
# `<:Real` is what left `Complex` distance matrices ambiguous before.
function Graphs.dijkstra_shortest_paths(
        graph::AbstractNamedGraph,
        srcs::Vector{<:Integer},
        distmx::AbstractMatrix{<:Number} = weights(graph);
        kwargs...
    )
    return namedgraph_dijkstra_shortest_paths(graph, srcs, distmx; kwargs...)
end

function Graphs.dijkstra_shortest_paths(
        graph::AbstractNamedGraph,
        vertex::Integer,
        distmx::AbstractMatrix = weights(graph);
        kwargs...
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

# These are not implemented for named graphs yet, but they still need methods
# that mirror the `AbstractGraph` signatures in Graphs.jl. Without them a call
# on a graph whose vertices happen to be integers is ambiguous, and resolving
# the ambiguity in Graphs.jl's favour would silently run the algorithm against
# vertex codes as though they were the vertex names. Erroring is the only safe
# answer until these are implemented. Bounds are copied from Graphs.jl.
function Graphs.bellman_ford_shortest_paths(
        graph::AbstractNamedGraph,
        sources::AbstractVector{<:Integer},
        distmx::AbstractMatrix{<:Number} = weights(graph)
    )
    return not_implemented()
end
function Graphs.bellman_ford_shortest_paths(
        graph::AbstractNamedGraph,
        source::Integer,
        distmx::AbstractMatrix{<:Number} = weights(graph)
    )
    return not_implemented()
end
function Graphs.desopo_pape_shortest_paths(
        graph::AbstractNamedGraph,
        source::Integer,
        distmx::AbstractMatrix{<:Number} = weights(graph)
    )
    return not_implemented()
end
function Graphs.floyd_warshall_shortest_paths(
        graph::AbstractNamedGraph, distmx::AbstractMatrix{<:Number} = weights(graph)
    )
    return not_implemented()
end
function Graphs.johnson_shortest_paths(
        graph::AbstractNamedGraph, distmx::AbstractMatrix{<:Number} = weights(graph)
    )
    return not_implemented()
end
# Graphs.jl constrains `source` and `target` to the same `U <: Integer`. That
# constraint is meaningless for named vertices, so this method exists only to
# resolve the ambiguity; named calls go to the generic method above.
function Graphs.yen_k_shortest_paths(
        graph::AbstractNamedGraph,
        source::U,
        target::U,
        distmx::AbstractMatrix{<:Number} = weights(graph),
        K::Int = 1;
        kwargs...
    ) where {U <: Integer}
    return not_implemented()
end
