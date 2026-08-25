using Graphs: Graphs, IsDirected, is_tree, nv, steiner_tree
using SimpleTraits: SimpleTraits, @traitfn, Not

function namedgraph_steiner_tree(
        g::AbstractNamedGraph, term_vert, distmx = weights(g)
    )
    coded_tree = steiner_tree(
        coded_graph(g),
        map(coded_vertex(g), term_vert),
        dist_matrix_to_coded_dist_matrix(g, distmx)
    )

    featured_vertices = Set{vertextype(g)}()

    tree_edges = edgetype(g)[]

    # Get only those vertices that appear in an edge
    for edge in edges(coded_tree)
        tree_edge = decoded_edge(g, edge)
        push!(tree_edges, tree_edge)
        push!(featured_vertices, src(tree_edge))
        push!(featured_vertices, dst(tree_edge))
    end

    tree = NamedGraph(featured_vertices)
    add_edges!(tree, tree_edges)

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
