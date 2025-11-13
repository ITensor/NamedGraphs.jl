using Dictionaries: Dictionary
using Graphs:
    AbstractEdge,
    AbstractGraph,
    Graphs,
    add_vertex!,
    dst,
    edgetype,
    has_vertex,
    is_directed,
    rem_vertex!,
    src,
    vertices
using ..NamedGraphs: NamedGraphs, AbstractNamedGraph, NamedGraph
using ..NamedGraphs.GraphsExtensions:
    GraphsExtensions, add_vertices!, not_implemented, rem_vertices!, subgraph, vertextype

# For you own graph type `g`, you should define a method for this function if you
# desire custom partitioning.
partitioned_vertices(g::AbstractGraph) = [vertices(g)]

# For fast quotient edge checking and graph construction, one should overload this function.
function quotient_graph(g::AbstractGraph)

    qg = NamedGraph(keys(partitioned_vertices(g)))

    for e in edges(g)
        qv_src = parent(quotientvertex(g, src(e)))
        qv_dst = parent(quotientvertex(g, dst(e)))
        qe = qv_src => qv_dst
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

# This method should not be overloaded by users
function quotient_graph_type(g)
    try
        return quotient_graph_type(typeof(g))
    catch e
        if e isa ErrorException
            return typeof(quotient_graph(g))
        else
            rethrow(e)
        end
    end
end
quotient_graph_type(::Type{<:AbstractGraph}) = not_implemented()
quotient_graph_vertextype(G) = vertextype(quotient_graph_type(G))
quotient_graph_edgetype(G) = edgetype(quotient_graph_type(G))

# The NamedGraph concrete type has no partitioning:
quotient_graph_type(::Type{<:NamedGraph}) = NamedGraph{Int}

# Additional interface functions

add_subquotientvertex!(pg::AbstractGraph, quotientvertex, vertex) = not_implemented()


"""
abstract type AbstractPartitionedGraph{V, PV} <: AbstractNamedGraph{V}

To use `AbstractPartitionedGraph` one should defined `unpartitioned_graph` that returns
an underlying graph *without* any partitioning. One should also define:
"""
abstract type AbstractPartitionedGraph{V, PV} <: AbstractNamedGraph{V} end

# Remove one layer of partitioning.
departition(pg::AbstractPartitionedGraph) = unpartitioned_graph(pg)
departition(g::AbstractGraph) = g

# Recursively remove all layers of partitioning.
function unpartition(pg::AbstractGraph)
    g = departition(pg)
    g === pg && return pg
    return unpartition(g)
end

# Required for interface
unpartitioned_graph(::AbstractPartitionedGraph) = not_implemented()
Base.copy(::AbstractPartitionedGraph) = not_implemented()

function unpartitioned_graph_type(::Type{<:AbstractPartitionedGraph})
    return not_implemented()
end
function GraphsExtensions.directed_graph_type(::Type{<:AbstractPartitionedGraph})
    return not_implemented()
end
function GraphsExtensions.undirected_graph_type(::Type{<:AbstractPartitionedGraph})
    return not_implemented()
end

function unpartitioned_graph_type(pg::AbstractPartitionedGraph)
    return typeof(unpartitioned_graph(pg))
end


# AbstractGraph interface.
function Graphs.is_directed(graph_type::Type{<:AbstractPartitionedGraph})
    return is_directed(unpartitioned_graph_type(graph_type))
end

#Functions for the abstract type
Graphs.vertices(pg::AbstractPartitionedGraph) = vertices(unpartitioned_graph(pg))
Graphs.edges(pg::AbstractPartitionedGraph) = edges(unpartitioned_graph(pg))

function NamedGraphs.position_graph(pg::AbstractPartitionedGraph)
    return NamedGraphs.position_graph(unpartitioned_graph(pg))
end
function NamedGraphs.vertex_positions(pg::AbstractPartitionedGraph)
    return NamedGraphs.vertex_positions(unpartitioned_graph(pg))
end
function NamedGraphs.ordered_vertices(pg::AbstractPartitionedGraph)
    return NamedGraphs.ordered_vertices(unpartitioned_graph(pg))
end
Graphs.edgetype(pg::AbstractPartitionedGraph) = edgetype(unpartitioned_graph(pg))

Graphs.rem_vertex!(::AbstractPartitionedGraph{V}, vertex::V) where {V} = not_implemented()

function Graphs.add_vertex!(::AbstractPartitionedGraph, vertex)
    return error("Need to specify a partition where the new vertex will go.")
end

function Graphs.add_vertex!(pg::AbstractPartitionedGraph, ssv::SubQuotientVertex)
    return add_subquotientvertex!(pg, ssv.vertex, ssv.subvertex)
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

function NamedGraphs._induced_subgraph(pg::AbstractPartitionedGraph, vlist)
    return NamedGraphs._induced_subgraph(unpartitioned_graph(pg), vlist)
end
