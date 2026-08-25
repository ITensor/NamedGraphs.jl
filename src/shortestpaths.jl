using Dictionaries: Dictionary
using Graphs: Graphs, dijkstra_shortest_paths, weights

"""
    struct NamedDijkstraState{V,T}

An `AbstractPathState` designed for Dijkstra shortest-paths calculations.
"""
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

function coded_path_state_to_path_state(
        graph::AbstractNamedGraph, coded_path_state::Graphs.DijkstraState
    )
    coded_path_state_parents = map(eachindex(coded_path_state.parents)) do i
        pᵢ = coded_path_state.parents[i]
        return iszero(pᵢ) ? i : pᵢ
    end
    decode = decoded_vertex(graph)
    return NamedDijkstraState(
        decode_keys(graph, map(decode, coded_path_state_parents)),
        decode_keys(graph, coded_path_state.dists),
        map(x -> map(decode, x), coded_path_state.predecessors),
        decode_keys(graph, coded_path_state.pathcounts),
        map(decode, coded_path_state.closest_vertices)
    )
end

function namedgraph_dijkstra_shortest_paths(
        graph::AbstractNamedGraph,
        srcs,
        distmx = weights(graph);
        allpaths = false,
        trackvertices = false
    )
    coded_path_state = dijkstra_shortest_paths(
        coded_graph(graph),
        map(coded_vertex(graph), srcs),
        dist_matrix_to_coded_dist_matrix(graph, distmx);
        allpaths,
        trackvertices
    )
    return coded_path_state_to_path_state(graph, coded_path_state)
end

function Graphs.dijkstra_shortest_paths(
        graph::AbstractNamedGraph, srcs, distmx = weights(graph); kwargs...
    )
    return namedgraph_dijkstra_shortest_paths(graph, srcs, distmx; kwargs...)
end

# Fix ambiguity error with `AbstractGraph` version
function Graphs.dijkstra_shortest_paths(
        graph::AbstractNamedGraph,
        srcs::Vector{<:Integer},
        distmx::AbstractMatrix{<:Real} = weights(graph);
        kwargs...
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
