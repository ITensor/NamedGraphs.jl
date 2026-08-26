using Dictionaries: Dictionary
using Graphs: Graphs, dfs_parents, dfs_tree, topological_sort_by_dfs
using SimpleTraits: SimpleTraits, @traitfn, Not

@traitfn function Graphs.topological_sort_by_dfs(g::AbstractNamedGraph::IsDirected)
    return map(c -> decode_vertex(g, c), topological_sort_by_dfs(encoded_graph(g)))
end

function namedgraph_dfs_tree(graph::AbstractNamedGraph, vertex; kwargs...)
    return Graphs.tree(graph, dfs_parents(graph, vertex; kwargs...))
end
function Graphs.dfs_tree(graph::AbstractNamedGraph, vertex::Integer; kwargs...)
    return namedgraph_dfs_tree(graph, vertex; kwargs...)
end
function Graphs.dfs_tree(graph::AbstractNamedGraph, vertex; kwargs...)
    return namedgraph_dfs_tree(graph, vertex; kwargs...)
end

# Returns a Dictionary mapping a vertex to it's parent
# vertex in the traversal/spanning tree.
function namedgraph_dfs_parents(graph::AbstractNamedGraph, vertex; kwargs...)
    encoded_dfs_parents = dfs_parents(
        encoded_graph(graph), encode_vertex(graph, vertex); kwargs...
    )
    graph_vertices = map(c -> decode_vertex(graph, c), vertices(encoded_graph(graph)))
    # Unreachable vertices have parent code 0; map them to themselves like
    # `dijkstra_shortest_paths` does.
    parents = map(eachindex(encoded_dfs_parents)) do c
        p = encoded_dfs_parents[c]
        return decode_vertex(graph, iszero(p) ? c : p)
    end
    return Dictionary(graph_vertices, parents)
end
# Disambiguation from Graphs.dfs_parents
function Graphs.dfs_parents(graph::AbstractNamedGraph, vertex::Integer; kwargs...)
    return namedgraph_dfs_parents(graph, vertex; kwargs...)
end
function Graphs.dfs_parents(graph::AbstractNamedGraph, vertex; kwargs...)
    return namedgraph_dfs_parents(graph, vertex; kwargs...)
end
