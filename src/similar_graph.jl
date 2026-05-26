using .GraphsExtensions: rem_edges, rem_vertices, similar_graph, similar_simplegraph
using SimpleTraits: SimpleTraits, @traitfn, Not

# =================================== `similar_graph` ==================================== #

function GraphsExtensions.similar_graph(graph::AbstractNamedGraph, vertices)
    return similar_namedgraph(graph, vertices)
end

@traitfn function similar_namedgraph(
        graph::AbstractGraph::(!IsDirected),
        vertices
    )
    V = eltype(vertices)
    return NamedGraph{V}(vertices)
end
@traitfn function similar_namedgraph(
        graph::AbstractGraph::IsDirected,
        vertices
    )
    V = eltype(vertices)
    return NamedDiGraph{V}(vertices)
end

similar_namedgraph(g::AbstractGraph, nv::Int) = similar_simplegraph(g, nv)
similar_namedgraph(g::AbstractGraph, ::Base.OneTo) = similar_graph(g, collect(vertices))

# Passing a type as a first argument attempts to call a constructor. Should be overloaded
# if the constructor doesnt exist for a given `AbstractGraph` concrete type.
function GraphsExtensions.similar_graph(T::Type{<:AbstractNamedGraph})
    return similar_graph(T, vertextype(T)[])
end

# =============================== `similar_dataless_graph` =============================== #
# This function behaves much the same as `similar_graph`, but should strictly return a
# a similar graph type that has no notion of data (in the abstract sense).

# Dimambiguation with `AbstractGraph` method in `GraphsExtensions`
@traitfn function GraphsExtensions.similar_dataless_graph(
        graph::AbstractNamedGraph::(!IsDirected),
        nv::Int
    )
    return SimpleGraph(nv)
end
@traitfn function GraphsExtensions.similar_dataless_graph(
        graph::AbstractNamedGraph::(IsDirected),
        nv::Int
    )
    return SimpleDiGraph(nv)
end
function GraphsExtensions.similar_dataless_graph(
        graph::AbstractNamedGraph,
        vertices::Base.OneTo
    )
    return similar_dataless_graph(graph, collect(vertices))
end

@traitfn function GraphsExtensions.similar_dataless_graph(
        graph::AbstractNamedGraph::(!IsDirected),
        vertices
    )
    return NamedGraph(vertices)
end

@traitfn function GraphsExtensions.similar_dataless_graph(
        graph::AbstractNamedGraph::IsDirected,
        vertices
    )
    return NamedDiGraph(vertices)
end
