using Graphs: Graphs, IsDirected, nv, steiner_tree
using SimpleTraits: SimpleTraits, @traitfn, Not

@traitfn function namedgraph_steiner_tree(
        g::AbstractNamedGraph::(!IsDirected), term_vert, distmx = weights(g)
    )
    position_tree = steiner_tree(
        position_graph(g),
        map(v -> vertex_positions(g)[v], term_vert),
        dist_matrix_to_position_dist_matrix(g, distmx)
    )
    tree =
        typeof(g)(position_tree, map(v -> ordered_vertices(g)[v], vertices(position_tree)))
    for v in copy(vertices(tree))
        iszero(degree(tree, v)) && rem_vertex!(tree, v)
    end
    return tree
end

@traitfn function Graphs.steiner_tree(
        g::AbstractNamedGraph::(!IsDirected), term_vert, args...
    )
    return namedgraph_steiner_tree(g, term_vert, args...)
end

@traitfn function Graphs.steiner_tree(
        g::AbstractNamedGraph::(!IsDirected), term_vert::Vector{<:Integer}, args...
    )
    return namedgraph_steiner_tree(g, term_vert, args...)
end
