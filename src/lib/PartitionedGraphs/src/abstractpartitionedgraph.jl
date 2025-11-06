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
using ..NamedGraphs: NamedGraphs, AbstractNamedGraph
using ..NamedGraphs.GraphsExtensions:
    GraphsExtensions, add_vertices!, not_implemented, rem_vertices!, subgraph

# Essential methods for fast quotient graph construction.
partitioned_vertices(g::AbstractGraph) = [vertices(g)]
quotient_edges(g::AbstractGraph, pvs = partitioned_vertices(g)) = keys(partitioned_edges(g, pvs))

# Overload this for fast inverse mapping for vertices and edges
find_quotient_vertex(g::AbstractGraph, vertex) = find_quotient_vertex(partitioned_vertices(g), vertex)

function find_quotient_vertex(pvs, vertex)
    rv = findfirst(pv -> vertex ∈ pv, pvs)
    if isnothing(rv)
        error("Vertex $vertex not found in any partition.")
    end
    return rv
end

function find_quotient_edge(g::AbstractGraph, edge, pvs = nothing)
    if !has_edge(g, edge)
        throw(ArgumentError("Graph does not have an edge $edge"))
    end
    gp = isnothing(pvs) ? g : pvs
    qv_src = find_quotient_vertex(gp, src(edge))
    qv_dst = find_quotient_vertex(gp, dst(edge))
    return NamedEdge(qv_src => qv_dst)
end

function partitioned_edges(g::AbstractGraph, pvs = nothing)
    if isnothing(pvs) 
        pvs = partitioned_vertices(g)
    end

    rv = Dictionary{NamedEdge{keytype(pvs)}, Vector{edgetype(g)}}()

    for e in edges(g)
        se = find_quotient_edge(g, e, pvs)
        if is_self_loop(se)
            continue
        end
        push!(get!(rv, se, typeof(e)[]), e)
    end

    return rv
end

quotient_vertices(g) = keys(partitioned_vertices(g))

function quotient_graph(g::AbstractGraph)
    qg = NamedGraph(quotient_vertices(g))
    add_edges!(qg, quotient_edges(g))
    return qg
end

function quotient_graph(g::AbstractGraph, pvs)
    qg = NamedGraph(keys(pvs))
    add_edges!(qg, quotient_edges(g, pvs))
    return qg
end

function is_boundary_edge(pg::AbstractGraph, edge::AbstractEdge)
    p_edge = superedge(pg, edge)
    return src(p_edge) == dst(p_edge)
end

function boundary_superedges(pg::AbstractGraph, supervertices; kwargs...)
    return SuperEdge.(
        boundary_edges(quotient_graph(pg), parent.(supervertices); kwargs...)
    )
end

function boundary_superedges(
        pg::AbstractGraph, supervertex::SuperVertex; kwargs...
    )
    return boundary_superedges(pg, [supervertex]; kwargs...)
end

"""
abstract type AbstractPartitionedGraph{V, PV} <: AbstractNamedGraph{V}

To use `AbstractPartitionedGraph` one should defined `unpartitioned_graph` that returns
an underlying graph *without* any partitioning. One should also define:
"""
abstract type AbstractPartitionedGraph{V, PV} <: AbstractNamedGraph{V} end

#Needed for interface
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

function GraphsExtensions.add_vertices!(
        pg::AbstractPartitionedGraph,
        vertices::Vector,
        supervertices::Vector{<:SuperVertex},
    )
    @assert length(vertices) == length(supervertices)
    for (v, sv) in zip(vertices, supervertices)
        add_vertex!(pg, v, sv)
    end

    return pg
end

function GraphsExtensions.add_vertices!(
        pg::AbstractPartitionedGraph, vertices::Vector, supervertex::SuperVertex
    )
    add_vertices!(pg, vertices, fill(supervertex, length(vertices)))
    return pg
end

Graphs.rem_vertex!(::AbstractPartitionedGraph{V}, vertex::V) where {V} = not_implemented()

function Graphs.add_vertex!(::AbstractPartitionedGraph, vertex)
    return error("Need to specify a partition where the new vertex will go.")
end

function Base.:(==)(pg1::AbstractPartitionedGraph, pg2::AbstractPartitionedGraph)
    if unpartitioned_graph(pg1) != unpartitioned_graph(pg2) ||
            QuotientView(pg1) != QuotientView(pg2)
        return false
    end
    for v in vertices(pg1)
        if supervertex(pg1, v) != supervertex(pg2, v)
            return false
        end
    end
    return true
end

function GraphsExtensions.subgraph( pg::AbstractPartitionedGraph, supervertex::SuperVertex)
    return first(induced_subgraph(unpartitioned_graph(pg), vertices(pg, [supervertex])))
end

function Graphs.induced_subgraph(
        pg::AbstractPartitionedGraph, supervertex::SuperVertex
    )
    return subgraph(pg, supervertex), nothing
end
