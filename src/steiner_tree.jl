using Graphs: Graphs, IsDirected, is_tree, nv, steiner_tree
using SimpleTraits: SimpleTraits, @traitfn, Not

function namedgraph_steiner_tree(
        g::AbstractNamedGraph, term_vert, distmx = weights(g)
    )
    position_tree = steiner_tree(
        position_graph(g),
        map(v -> vertex_positions(g)[v], term_vert),
        dist_matrix_to_position_dist_matrix(g, distmx)
    )

    vertex_map = ordered_vertices(g)
    edge_map = e -> edgetype(g)(vertex_map[src(e)] => vertex_map[dst(e)])

    featured_vertices = Set{vertextype(g)}()

    named_edges = edgetype(g)[]

    # Get only those vertices that appear in an edge
    for edge in edges(position_tree)
        named_edge = edge_map(edge)
        push!(named_edges, named_edge)
        push!(featured_vertices, src(named_edge))
        push!(featured_vertices, dst(named_edge))
    end

    tree = similar_tree(g, featured_vertices, named_edges)

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
