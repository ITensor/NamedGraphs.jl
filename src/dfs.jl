using Graphs: Graphs, dfs_parents, dfs_tree, topological_sort_by_dfs
using SimpleTraits: SimpleTraits, @traitfn, Not

@traitfn function Graphs.topological_sort_by_dfs(g::AbstractNamedGraph::IsDirected)
    return map(decoded_vertex(g), topological_sort_by_dfs(coded_graph(g)))
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
    coded_dfs_parents = dfs_parents(
        coded_graph(graph), coded_vertex(graph, vertex); kwargs...
    )
    return dictionary(
        decoded_vertex(graph, c) => decoded_vertex(graph, p) for
            (c, p) in pairs(coded_dfs_parents)
    )
end
# Disambiguation from Graphs.dfs_parents
function Graphs.dfs_parents(graph::AbstractNamedGraph, vertex::Integer; kwargs...)
    return namedgraph_dfs_parents(graph, vertex; kwargs...)
end
function Graphs.dfs_parents(graph::AbstractNamedGraph, vertex; kwargs...)
    return namedgraph_dfs_parents(graph, vertex; kwargs...)
end
