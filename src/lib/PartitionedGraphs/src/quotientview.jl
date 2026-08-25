using ..NamedGraphs: NamedGraph, encoded_graph_type, induced_subgraph_from_vertices
using ..SimilarType: similar_type
using .GraphsExtensions: directed_graph_type, undirected_graph_type
using Graphs: AbstractGraph, edges, has_edge, rem_edge!, rem_vertex!, vertices

struct QuotientView{V, G <: AbstractGraph} <: AbstractNamedGraph{V}
    graph::G
    QuotientView(graph::G) where {G} = new{quotient_graph_vertextype(graph), G}(graph)
end

Base.parent(qg::QuotientView) = qg.graph
parent_graph_type(g::AbstractGraph) = parent_graph_type(typeof(g))
parent_graph_type(::Type{<:QuotientView{V, G}}) where {V, G} = G

Base.copy(qv::QuotientView) = copy(quotient_graph(parent(qv)))

function NamedGraphs.edgetype(Q::Type{<:QuotientView})
    return quotient_graph_edgetype(parent_graph_type(Q))
end

Graphs.vertices(qg::QuotientView) = keys(partitioned_vertices(parent(qg)))
Graphs.edges(qg::QuotientView) = edges(quotient_graph(parent(qg)))

function NamedGraphs.encoded_graph_type(type::Type{<:QuotientView})
    return encoded_graph_type(quotient_graph_type(parent_graph_type(type)))
end

function NamedGraphs.GraphsExtensions.directed_graph_type(type::Type{<:QuotientView})
    return directed_graph_type(quotient_graph_type(parent_graph_type(type)))
end
function NamedGraphs.GraphsExtensions.undirected_graph_type(type::Type{<:QuotientView})
    return undirected_graph_type(quotient_graph_type(parent_graph_type(type)))
end

function Graphs.rem_vertex!(qg::QuotientView, v)
    rem_quotientvertex!(parent(qg), QuotientVertex(v))
    return qg
end
function Graphs.rem_edge!(qg::QuotientView, v)
    rem_quotientedge!(parent(qg), QuotientEdge(v))
    return qg
end

NamedGraphs.encoded_graph(g::QuotientView) = NamedGraphs.encoded_graph(copy(g))
function NamedGraphs.encode_vertex(g::QuotientView, vertex)
    return NamedGraphs.encode_vertex(copy(g), vertex)
end
function NamedGraphs.decode_vertex(g::QuotientView, code::Integer)
    return NamedGraphs.decode_vertex(copy(g), code)
end

function NamedGraphs.SimilarType.similar_type(type::Type{<:QuotientView})
    return similar_type(quotient_graph_type(parent_graph_type(type)))
end

quotientview(g::AbstractGraph) = QuotientView(g)

function NamedGraphs.induced_subgraph_from_vertices(g::QuotientView, vertices)
    subgraph, subvertices = induced_subgraph(parent(g), to_quotient_index(vertices))
    return QuotientView(subgraph), subvertices
end

NamedGraphs.getindex_namedgraph(qv::QuotientView, ind) = parent(qv)[to_quotient_index(ind)]
