using ..NamedGraphs: AbstractNamedGraph, NamedDiGraph, NamedGraph, NamedGraphs,
    convert_vertextype, get_graph_index, not_implemented, subgraph
using Dictionaries: Dictionary
using Graphs: Graphs, AbstractEdge, AbstractGraph, AbstractSimpleGraph, add_vertex!, dst,
    edgetype, has_vertex, is_directed, rem_vertex!, src, vertices

"""
    partitioned_vertices(graph::AbstractGraph)

The partitioning of the vertices of `graph`: a mapping from each quotient vertex
to the collection of vertices of `graph` it contains. Overload this on your own
graph type to give it a non-trivial partitioning; the fallback puts every vertex
into a single quotient vertex.

# Examples

```jldoctest
julia> using Graphs: path_graph

julia> using NamedGraphs: NamedGraph

julia> using NamedGraphs.PartitionedGraphs: PartitionedGraph, partitioned_vertices

julia> g = NamedGraph(path_graph(4), ["a", "b", "c", "d"]);

julia> pvs = partitioned_vertices(PartitionedGraph(g, [["a", "b"], ["c", "d"]]));

julia> pvs[1]
2-element Vector{String}:
 "a"
 "b"

julia> pvs[2]
2-element Vector{String}:
 "c"
 "d"
```
"""
partitioned_vertices(g::AbstractGraph) = [vertices(g)]

#TODO: Write this in terms of traits
function similar_quotient_graph(g::AbstractGraph)
    if is_directed(g)
        sg = NamedDiGraph()
    else
        sg = NamedGraph()
    end
    return convert_vertextype(keytype(partitioned_vertices(g)), sg)
end

"""
    quotient_graph(graph::AbstractGraph)

The graph on the quotient vertices of `graph`, with an edge between two quotient
vertices whenever `graph` has an edge between them. Its vertices are the quotient
vertices themselves rather than [`QuotientVertex`](@ref) wrappers, and
[`QuotientView`](@ref) is the corresponding lazy view that mutates `graph` when
it is mutated.

Overload this on your own graph type for fast quotient graph construction and
fast quotient level `has_edge`; the fallback builds it from
[`partitioned_vertices`](@ref) and the edges of `graph`.

# Examples

```jldoctest
julia> using Graphs: ne, nv, path_graph, vertices

julia> using NamedGraphs: NamedGraph

julia> using NamedGraphs.PartitionedGraphs: PartitionedGraph, quotient_graph

julia> g = NamedGraph(path_graph(4), ["a", "b", "c", "d"]);

julia> qg = quotient_graph(PartitionedGraph(g, [["a", "b"], ["c", "d"]]));

julia> (nv(qg), ne(qg))
(2, 1)

julia> issetequal(vertices(qg), [1, 2])
true
```
"""
function quotient_graph(g::AbstractGraph)
    qg = similar_quotient_graph(g)

    for qv in keys(partitioned_vertices(g))
        add_vertex!(qg, qv)
    end

    for e in edges(g)
        qv_src = parent(quotientvertex(g, src(e)))
        qv_dst = parent(quotientvertex(g, dst(e)))
        qe = edgetype(qg)(qv_src => qv_dst)
        if qv_src != qv_dst && !has_edge(qg, qe)
            add_edge!(qg, qe)
        end
    end

    return qg
end

function partitioned_edges(g::AbstractGraph)
    dict = Dictionary{quotient_graph_edgetype(g), Vector{edgetype(g)}}()

    for e in edges(g)
        qe = parent(quotientedge(g, e))

        if is_self_loop(qe)
            continue
        end
        push!(get!(dict, qe, edgetype(g)[]), e)
    end

    return dict
end

function is_partition_boundary_edge(pg::AbstractGraph, edge)
    p_edge = quotientedge(pg, edge)
    return src(p_edge) != dst(p_edge)
end

"""
    boundary_quotientedges(graph::AbstractGraph, quotientvertices; dir = :out)
    boundary_quotientedges(graph::AbstractGraph, quotientvertex::QuotientVertex; dir = :out)

The [`QuotientEdge`](@ref)s of `graph` that connect the given quotient vertices
to the quotient vertices outside of them, i.e. the boundary edges of
`quotientvertices` in the quotient graph of `graph`.

Keyword arguments are forwarded to `boundary_edges`, in
particular `dir`, which selects the edge direction to consider in a directed
graph.
"""
function boundary_quotientedges(pg::AbstractGraph, quotientvertices; kwargs...)
    return QuotientEdge.(
        boundary_edges(quotient_graph(pg), parent.(quotientvertices); kwargs...)
    )
end

function boundary_quotientedges(
        pg::AbstractGraph, quotientvertex::QuotientVertex; kwargs...
    )
    return boundary_quotientedges(pg, [quotientvertex]; kwargs...)
end

quotient_graph_type(g::AbstractGraph) = quotient_graph_type(typeof(g))
quotient_graph_type(G::Type{<:AbstractGraph}) = Base.promote_op(quotient_graph, G)
quotient_graph_vertextype(G) = vertextype(quotient_graph_type(G))
quotient_graph_edgetype(G) = edgetype(quotient_graph_type(G))

# Additional interface functions

add_subquotientvertex!(pg::AbstractGraph, quotientvertex, vertex) = not_implemented()

"""
    abstract type AbstractPartitionedGraph{V, PV} <: AbstractNamedGraph{V}

Supertype for named graphs that carry a partitioning of their vertices, with
vertex type `V` and quotient vertex type `PV`.

A subtype must define `unpartitioned_graph`, returning the underlying graph
*without* any partitioning, on top of the partitioned-graph interface documented
in [`PartitionedGraphs`](@ref). Note that interface can also be implemented by a
graph type that does not subtype `AbstractPartitionedGraph`.
"""
abstract type AbstractPartitionedGraph{V, PV} <: AbstractNamedGraph{V} end

"""
    departition(graph::AbstractGraph)

The graph underlying `graph` with a single layer of partitioning removed: the
graph that was partitioned to make `graph`, without the partitioning. Graphs
that are not an [`AbstractPartitionedGraph`](@ref) are returned as-is, so
`departition` is the identity on them.

Note that a partitioned graph can itself be partitioned, so removing one layer
may leave a graph that is still partitioned. Use [`unpartition`](@ref) to remove
every layer at once.

# Examples

```jldoctest
julia> using Graphs: path_graph

julia> using NamedGraphs: NamedGraph

julia> using NamedGraphs.PartitionedGraphs: departition, partitionedgraph

julia> g = NamedGraph(path_graph(4), ["a", "b", "c", "d"]);

julia> pg = partitionedgraph(g, [["a", "b"], ["c", "d"]]);

julia> departition(pg) === g
true

julia> departition(g) === g
true

julia> departition(partitionedgraph(pg, [["a", "c"], ["b", "d"]])) === pg
true
```
"""
departition(pg::AbstractPartitionedGraph) = unpartitioned_graph(pg)
departition(g::AbstractGraph) = g

"""
    unpartition(graph::AbstractGraph)

The graph underlying `graph` with every layer of partitioning removed, i.e.
[`departition`](@ref) applied repeatedly until the result is no longer
partitioned. Graphs that are not an [`AbstractPartitionedGraph`](@ref) are
returned as-is.

# Examples

```jldoctest
julia> using Graphs: path_graph

julia> using NamedGraphs: NamedGraph

julia> using NamedGraphs.PartitionedGraphs: partitionedgraph, unpartition

julia> g = NamedGraph(path_graph(4), ["a", "b", "c", "d"]);

julia> pg = partitionedgraph(g, [["a", "b"], ["c", "d"]]);

julia> pg2 = partitionedgraph(pg, [["a", "c"], ["b", "d"]]);

julia> unpartition(pg2) === g
true

julia> unpartition(g) === g
true
```
"""
function unpartition(pg::AbstractGraph)
    g = departition(pg)
    g === pg && return pg
    return unpartition(g)
end

"""
    unpartitioned_graph(graph::AbstractPartitionedGraph)

The graph that was partitioned to make `graph`, without the partitioning. Every
[`AbstractPartitionedGraph`](@ref) subtype must overload this, on top of the
partitioned graph interface documented in [`PartitionedGraphs`](@ref).

[`departition`](@ref) is the equivalent that also accepts graphs that are not
partitioned, returning them as-is.
"""
unpartitioned_graph(::AbstractPartitionedGraph) = not_implemented()

# Required for interface
Base.copy(::AbstractPartitionedGraph) = not_implemented()

function unpartitioned_graph_type(::Type{<:AbstractPartitionedGraph})
    return not_implemented()
end
function NamedGraphs.directed_graph_type(::Type{<:AbstractPartitionedGraph})
    return not_implemented()
end
function NamedGraphs.undirected_graph_type(::Type{<:AbstractPartitionedGraph})
    return not_implemented()
end

function unpartitioned_graph_type(pg::AbstractPartitionedGraph)
    return typeof(unpartitioned_graph(pg))
end

function NamedGraphs.get_graph_index(pg::AbstractPartitionedGraph, ind)
    return get_graph_index(unpartitioned_graph(pg), ind)
end

#Functions for the abstract type
Graphs.vertices(pg::AbstractPartitionedGraph) = vertices(unpartitioned_graph(pg))
Graphs.edges(pg::AbstractPartitionedGraph) = edges(unpartitioned_graph(pg))

function NamedGraphs.encoded_graph(pg::AbstractPartitionedGraph)
    return NamedGraphs.encoded_graph(unpartitioned_graph(pg))
end
function NamedGraphs.encoded_vertex(pg::AbstractPartitionedGraph, vertex)
    return NamedGraphs.encoded_vertex(unpartitioned_graph(pg), vertex)
end
function NamedGraphs.decoded_vertex(pg::AbstractPartitionedGraph, code::Integer)
    return NamedGraphs.decoded_vertex(unpartitioned_graph(pg), code)
end
Graphs.edgetype(pg::AbstractPartitionedGraph) = edgetype(unpartitioned_graph(pg))

Graphs.rem_vertex!(::AbstractPartitionedGraph{V}, vertex::V) where {V} = not_implemented()

function Graphs.add_vertex!(::AbstractPartitionedGraph, vertex)
    return error("Need to specify a partition where the new vertex will go.")
end

function Graphs.add_vertex!(pg::AbstractPartitionedGraph, qvv::QuotientVertexVertex)
    return add_subquotientvertex!(pg, qvv.quotientvertex, qvv.vertex)
end

function Base.:(==)(pg1::AbstractPartitionedGraph, pg2::AbstractPartitionedGraph)
    if unpartitioned_graph(pg1) != unpartitioned_graph(pg2) ||
            QuotientView(pg1) != QuotientView(pg2)
        return false
    end
    for v in vertices(pg1)
        if quotientvertex(pg1, v) != quotientvertex(pg2, v)
            return false
        end
    end
    return true
end

function NamedGraphs.induced_subgraph_from_vertices(
        pg::AbstractPartitionedGraph,
        subvertices
    )
    return induced_subgraph(unpartitioned_graph(pg), subvertices)
end
