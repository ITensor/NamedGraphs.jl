using Graphs.SimpleGraphs: AbstractSimpleGraph

function permute_vertices(graph::AbstractSimpleGraph, permutation)
    return graph[permutation]
end

# https://github.com/JuliaGraphs/Graphs.jl/issues/365
similar_graph(graph_type::Type{<:AbstractSimpleGraph}) = graph_type()
function similar_graph(graph::AbstractSimpleGraph, vertices::Base.OneTo)
    return similar_graph(typeof(graph), vertices)
end
function similar_graph(graph_type::Type{<:AbstractSimpleGraph}, vertices::Base.OneTo)
    return graph_type(length(vertices))
end

function convert_vertextype(vertextype::Type, graph::AbstractSimpleGraph)
    return not_implemented()
end

using Graphs.SimpleGraphs: SimpleDiGraph, SimpleGraph

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
