using Graphs:
    Graphs,
    AbstractEdge,
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
    GraphsExtensions, add_vertices!, not_implemented, rem_vertices!

abstract type AbstractPartitionedGraph{V, PV} <: AbstractNamedGraph{V} end

#Needed for interface
quotient_graph(pg::AbstractPartitionedGraph) = not_implemented()
unpartitioned_graph(pg::AbstractPartitionedGraph) = not_implemented()
function unpartitioned_graph_type(pg::Type{<:AbstractPartitionedGraph})
    return not_implemented()
end
partitionvertex(pg::AbstractPartitionedGraph, vertex) = not_implemented()
partitionvertices(pg::AbstractPartitionedGraph, verts) = not_implemented()
partitionvertices(pg::AbstractPartitionedGraph) = not_implemented()
Base.copy(pg::AbstractPartitionedGraph) = not_implemented()
delete_from_vertex_map!(pg::AbstractPartitionedGraph, vertex) = not_implemented()
insert_to_vertex_map!(pg::AbstractPartitionedGraph, vertex) = not_implemented()
partitionedge(pg::AbstractPartitionedGraph, edge) = not_implemented()
partitionedges(pg::AbstractPartitionedGraph, edges) = not_implemented()
partitionedges(pg::AbstractPartitionedGraph) = not_implemented()
function unpartitioned_graph_type(pg::AbstractPartitionedGraph)
    return typeof(unpartitioned_graph(pg))
end

function Graphs.edges(pg::AbstractPartitionedGraph, partitionedge::AbstractPartitionEdge)
    return not_implemented()
end
function Graphs.vertices(pg::AbstractPartitionedGraph, pv::AbstractPartitionVertex)
    return not_implemented()
end
function Graphs.vertices(
        pg::AbstractPartitionedGraph, partitionverts::Vector{V}
    ) where {V <: AbstractPartitionVertex}
    return not_implemented()
end
function GraphsExtensions.directed_graph_type(PG::Type{<:AbstractPartitionedGraph})
    return not_implemented()
end
function GraphsExtensions.undirected_graph_type(PG::Type{<:AbstractPartitionedGraph})
    return not_implemented()
end

# AbstractGraph interface.
function Graphs.is_directed(graph_type::Type{<:AbstractPartitionedGraph})
    return is_directed(unpartitioned_graph_type(graph_type))
end

#Functions for the abstract type
Graphs.vertices(pg::AbstractPartitionedGraph) = vertices(unpartitioned_graph(pg))
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
function Graphs.nv(pg::AbstractPartitionedGraph, pv::AbstractPartitionVertex)
    return length(vertices(pg, pv))
end
function Graphs.has_vertex(
        pg::AbstractPartitionedGraph, partitionvertex::AbstractPartitionVertex
    )
    return has_vertex(quotient_graph(pg), parent(partitionvertex))
end

function Graphs.has_edge(pg::AbstractPartitionedGraph, partitionedge::AbstractPartitionEdge)
    return has_edge(quotient_graph(pg), parent(partitionedge))
end

function is_boundary_edge(pg::AbstractPartitionedGraph, edge::AbstractEdge)
    p_edge = partitionedge(pg, edge)
    return src(p_edge) == dst(p_edge)
end

function Graphs.add_edge!(pg::AbstractPartitionedGraph, edge::AbstractEdge)
    add_edge!(unpartitioned_graph(pg), edge)
    pg_edge = parent(partitionedge(pg, edge))
    if src(pg_edge) != dst(pg_edge)
        add_edge!(quotient_graph(pg), pg_edge)
    end
    return pg
end

function Graphs.rem_edge!(pg::AbstractPartitionedGraph, edge::AbstractEdge)
    pg_edge = partitionedge(pg, edge)
    if has_edge(quotient_graph(pg), pg_edge)
        g_edges = edges(pg, pg_edge)
        if length(g_edges) == 1
            rem_edge!(quotient_graph(pg), pg_edge)
        end
    end
    return rem_edge!(unpartitioned_graph(pg), edge)
end

function Graphs.rem_edge!(
        pg::AbstractPartitionedGraph, partitionedge::AbstractPartitionEdge
    )
    return rem_edges!(pg, edges(pg, parent(partitionedge)))
end

#Vertex addition and removal. I think it's important not to allow addition of a vertex without specification of PV
function Graphs.add_vertex!(
        pg::AbstractPartitionedGraph, vertex, partitionvertex::AbstractPartitionVertex
    )
    add_vertex!(unpartitioned_graph(pg), vertex)
    add_vertex!(quotient_graph(pg), parent(partitionvertex))
    insert_to_vertex_map!(pg, vertex, partitionvertex)
    return pg
end

function GraphsExtensions.add_vertices!(
        pg::AbstractPartitionedGraph,
        vertices::Vector,
        partitionvertices::Vector{<:AbstractPartitionVertex},
    )
    @assert length(vertices) == length(partitionvertices)
    for (v, pv) in zip(vertices, partitionvertices)
        add_vertex!(pg, v, pv)
    end

    return pg
end

function GraphsExtensions.add_vertices!(
        pg::AbstractPartitionedGraph, vertices::Vector, partitionvertex::AbstractPartitionVertex
    )
    add_vertices!(pg, vertices, fill(partitionvertex, length(vertices)))
    return pg
end

function Graphs.rem_vertex!(pg::AbstractPartitionedGraph, vertex)
    pv = partitionvertex(pg, vertex)
    delete_from_vertex_map!(pg, pv, vertex)
    rem_vertex!(unpartitioned_graph(pg), vertex)
    if !haskey(partitioned_vertices(pg), parent(pv))
        rem_vertex!(quotient_graph(pg), parent(pv))
    end
    return pg
end

function Graphs.rem_vertex!(
        pg::AbstractPartitionedGraph, partitionvertex::AbstractPartitionVertex
    )
    rem_vertices!(pg, vertices(pg, partitionvertex))
    return pg
end

function GraphsExtensions.rem_vertex(
        pg::AbstractPartitionedGraph, partitionvertex::AbstractPartitionVertex
    )
    pg_new = copy(pg)
    rem_vertex!(pg_new, partitionvertex)
    return pg_new
end

function Graphs.add_vertex!(pg::AbstractPartitionedGraph, vertex)
    return error("Need to specify a partition where the new vertex will go.")
end

function Base.:(==)(pg1::AbstractPartitionedGraph, pg2::AbstractPartitionedGraph)
    if unpartitioned_graph(pg1) != unpartitioned_graph(pg2) ||
            quotient_graph(pg1) != quotient_graph(pg2)
        return false
    end
    for v in vertices(pg1)
        if partitionvertex(pg1, v) != partitionvertex(pg2, v)
            return false
        end
    end
    return true
end

function GraphsExtensions.subgraph(
        pg::AbstractPartitionedGraph, partitionvertex::AbstractPartitionVertex
    )
    return first(induced_subgraph(unpartitioned_graph(pg), vertices(pg, [partitionvertex])))
end

function Graphs.induced_subgraph(
        pg::AbstractPartitionedGraph, partitionvertex::AbstractPartitionVertex
    )
    return subgraph(pg, partitionvertex), nothing
end
