using .GraphsExtensions: BFS, DFS, RandomBFS, default_root_vertex,
    default_spanning_tree_alg, post_order_dfs_edges, random_bfs_tree,
    similar_dataless_graph, subgraph
using Graphs: IsDirected, bfs_tree, connected_components, dfs_tree, edges, edgetype
using SimpleTraits: SimpleTraits, @traitfn, Not

function spanning_tree(
        g::AbstractNamedGraph; alg = default_spanning_tree_alg(),
        root_vertex = default_root_vertex(g)
    )
    return spanning_tree(alg, g; root_vertex)
end

@traitfn function spanning_tree(
        ::BFS, g::AbstractNamedGraph::(!IsDirected); root_vertex = default_root_vertex(g)
    )
    return undirected_graph(bfs_tree(g, root_vertex))
end

@traitfn function spanning_tree(
        ::RandomBFS, g::AbstractNamedGraph::(!IsDirected);
        root_vertex = default_root_vertex(g)
    )
    return undirected_graph(random_bfs_tree(g, root_vertex))
end

@traitfn function spanning_tree(
        ::DFS, g::AbstractNamedGraph::(!IsDirected); root_vertex = default_root_vertex(g)
    )
    return undirected_graph(dfs_tree(g, root_vertex))
end

# Split the graph into its connected components, build a spanning tree over each
# of them with `spanning_tree`, and take the union.
function spanning_forest(
        g::AbstractNamedGraph; spanning_tree = spanning_tree
    )
    return reduce(union, (spanning_tree(subgraph(g, vs)) for vs in connected_components(g)))
end

"""
    forest_cover(graph::AbstractNamedGraph; spanning_tree=spanning_tree)

A vector of graphs, each a spanning forest over all the vertices of `graph`,
whose edge sets partition the edges of `graph`. The forests are collected
greedily, so their number is an upper bound on the
[arboricity](https://en.wikipedia.org/wiki/Arboricity) rather than the minimum.
"""
function forest_cover(g::AbstractNamedGraph; spanning_tree = spanning_tree)
    g = similar_dataless_graph(g)
    g_reduced = g

    remaining_edges = collect(edges(g))
    edges_collected = empty(remaining_edges)

    forests = typeof(g)[]
    while !isempty(remaining_edges)
        g_reduced_spanning_forest = spanning_forest(g_reduced; spanning_tree)
        edges_collected = [edges_collected; collect(edges(g_reduced_spanning_forest))]
        g_reduced = rem_edges(g, edges_collected)
        forests = [forests; [g_reduced_spanning_forest]]
        remaining_edges = setdiff(remaining_edges, edges(g_reduced_spanning_forest))
    end
    # Narrow the element type if possible.
    return identity.(forests)
end

"""
    forest_cover_edge_sequence(graph::AbstractNamedGraph; root_vertex=default_root_vertex)

An ordering of the edges of `graph` that visits every edge in both directions,
built by sweeping each tree of each forest of [`forest_cover`](@ref) inwards to
its root in [`post_order_dfs_edges`](@ref) order and then back outwards.
`root_vertex` is a function picking the root of each tree, such as
[`default_root_vertex`](@ref).
"""
function forest_cover_edge_sequence(
        g::AbstractNamedGraph; root_vertex = default_root_vertex
    )
    forests = forest_cover(g)
    rv = edgetype(g)[]
    for forest in forests
        trees = [subgraph(forest, vs) for vs in connected_components(forest)]
        for tree in trees
            tree_edges = post_order_dfs_edges(tree, root_vertex(tree))
            push!(rv, vcat(tree_edges, reverse(reverse.(tree_edges)))...)
        end
    end
    return rv
end
