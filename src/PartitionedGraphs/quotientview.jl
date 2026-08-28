using ..NamedGraphs:
    NamedGraph, encoded_graph_type, induced_subgraph_from_vertices, similar_type
using .GraphsExtensions: directed_graph_type, undirected_graph_type
using Graphs: AbstractGraph, edges, has_edge, rem_edge!, rem_vertex!, vertices

"""
    QuotientView(graph::AbstractGraph)

A view of `graph` as its quotient graph: the graph whose vertices are the
quotient vertices of `graph` and which has an edge between two quotient vertices
whenever `graph` has an edge between them. Its vertices are the quotient
vertices themselves rather than [`QuotientVertex`](@ref) wrappers, so it can be
used with the `Graphs.jl` interface like any other named graph.

The view is backed by `graph`, so mutating it mutates `graph`: removing a vertex
of the view removes all of the vertices of `graph` in that quotient vertex, and
removing an edge of the view removes all of the edges of `graph` between those
two quotient vertices.

Any `Graphs.AbstractGraph` can be viewed this way. A graph with no partitioning
defined has the trivial partitioning with all of its vertices in a single
quotient vertex, so its quotient graph is a single vertex with no edges.

# Examples

```jldoctest
julia> using Graphs: edges, ne, nv, path_graph, vertices

julia> using NamedGraphs: NamedEdge, NamedGraph

julia> using NamedGraphs.PartitionedGraphs: PartitionedGraph, QuotientView

julia> g = NamedGraph(path_graph(4), ["a", "b", "c", "d"]);

julia> pg = PartitionedGraph(g, [["a", "b"], ["c", "d"]]);

julia> qg = QuotientView(pg);

julia> collect(vertices(qg))
2-element Vector{Int64}:
 1
 2

julia> collect(edges(qg))
1-element Vector{NamedEdge{Int64}}:
 1 => 2

julia> (nv(QuotientView(g)), ne(QuotientView(g)))
(1, 0)
```
"""
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
    has_vertex(qg, v) || return false
    rem_quotientvertex!(parent(qg), QuotientVertex(v))
    return true
end
function Graphs.rem_edge!(qg::QuotientView, e)
    e = edgetype(qg)(e)
    has_edge(qg, e) || return false
    rem_quotientedge!(parent(qg), QuotientEdge(e))
    return true
end

NamedGraphs.encoded_graph(g::QuotientView) = NamedGraphs.encoded_graph(copy(g))
function NamedGraphs.encode_vertex(g::QuotientView, vertex)
    return NamedGraphs.encode_vertex(copy(g), vertex)
end
function NamedGraphs.decode_vertex(g::QuotientView, code::Integer)
    return NamedGraphs.decode_vertex(copy(g), code)
end

function NamedGraphs.similar_type(type::Type{<:QuotientView})
    return similar_type(quotient_graph_type(parent_graph_type(type)))
end

quotientview(g::AbstractGraph) = QuotientView(g)

function NamedGraphs.induced_subgraph_from_vertices(g::QuotientView, vertices)
    subgraph, subvertices = induced_subgraph(parent(g), to_quotient_index(vertices))
    return QuotientView(subgraph), subvertices
end

# Override the scalar hook rather than `getindex_namedgraph` itself, which would
# shadow the `AbstractGraphIndices` dispatch and make `qv[Vertices(...)]`
# ambiguous. Collection indexing then flows through `get_graph_indices` to
# `induced_subgraph_from_vertices` above.
function NamedGraphs.get_graph_index(qv::QuotientView, index)
    return parent(qv)[to_quotient_index(index)]
end
