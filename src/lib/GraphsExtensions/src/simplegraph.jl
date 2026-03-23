using Graphs.SimpleGraphs: AbstractSimpleGraph, SimpleDiGraph, SimpleEdge, SimpleGraph
using SimpleTraits: SimpleTraits, @traitfn, Not

function permute_vertices(graph::AbstractSimpleGraph, permutation)
    return graph[permutation]
end

# https://github.com/JuliaGraphs/Graphs.jl/issues/365
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

@traitfn function directed_graph(graph::AbstractSimpleGraph::(!IsDirected))
    digraph = similar_simplegraph(directed_graph_type(graph), vertices(graph), edges(graph))
    for e in edges(graph)
        add_edge!(digraph, reverse(e))
    end
    return digraph
end

# Must have the same argument name as:
# @traitfn undirected_graph(graph::::(!IsDirected))
# to avoid method overwrite warnings, see:
# https://github.com/mauro3/SimpleTraits.jl#method-overwritten-warnings
@traitfn function undirected_graph(graph::AbstractSimpleGraph::IsDirected)
    undigraph = similar_simplegraph(undirected_graph_type(graph), vertices(graph))
    for e in edges(graph)
        has_edge(undigraph, e) && continue
        add_edge!(undigraph, e)
    end
    return undigraph
end
