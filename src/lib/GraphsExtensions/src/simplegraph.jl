using Graphs.SimpleGraphs: AbstractSimpleGraph, SimpleDiGraph, SimpleEdge, SimpleGraph

function permute_vertices(graph::AbstractSimpleGraph, permutation)
    return graph[permutation]
end

# https://github.com/JuliaGraphs/Graphs.jl/issues/365
similar_graph(T::Type{<:AbstractSimpleGraph}) = similar_graph(T, Base.OneTo(0))
function similar_graph(T::Type{<:AbstractSimpleGraph}, vertices::Base.OneTo, edges)
    new_graph = T(length(vertices))
    add_edges!(new_graph, edges)
    return new_graph
end

function convert_vertextype(vertextype::Type, graph::AbstractSimpleGraph)
    return not_implemented()
end

convert_vertextype(V::Type, E::Type{<:SimpleEdge}) = SimpleEdge{V}

function convert_vertextype(vertextype::Type, graph::SimpleGraph)
    return SimpleGraph{vertextype}(graph)
end
function convert_vertextype(vertextype::Type, graph::SimpleDiGraph)
    return SimpleDiGraph{vertextype}(graph)
end

directed_graph_type(G::Type{<:SimpleGraph}) = SimpleDiGraph{vertextype(G)}
# TODO: Use traits to make this more general.
undirected_graph_type(G::Type{<:SimpleGraph}) = G

# TODO: Use traits to make this more general.
directed_graph_type(G::Type{<:SimpleDiGraph}) = G
undirected_graph_type(G::Type{<:SimpleDiGraph}) = SimpleGraph{vertextype(G)}
