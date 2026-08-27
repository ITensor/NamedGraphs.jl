using Graphs: Graphs, IsDirected, is_tree, nv, steiner_tree, weights
using SimpleTraits: SimpleTraits, @traitfn, Not

function namedgraph_steiner_tree(
        g::AbstractNamedGraph, term_vert, distmx = weights(g)
    )
    encoded_tree = steiner_tree(
        encoded_graph(g),
        map(v -> encode_vertex(g, v), term_vert),
        encode_dist_matrix(g, distmx)
    )

    featured_vertices = Set{vertextype(g)}()

    tree_edges = edgetype(g)[]

    # Get only those vertices that appear in an edge
    for edge in edges(encoded_tree)
        tree_edge = decode_edge(g, edge)
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

# Mirrors the `AbstractGraph` signature in Graphs.jl so the wrapper above is
# not ambiguous with it. Graphs.jl bounds this `distmx` as `<:Real`, unlike the
# `<:Number` it uses elsewhere.
@traitfn function Graphs.steiner_tree(
        g::AbstractNamedGraph::(!IsDirected),
        term_vert::Vector{<:Integer},
        distmx::AbstractMatrix{<:Real} = weights(g)
    )
    return namedgraph_steiner_tree(g, term_vert, distmx)
end
