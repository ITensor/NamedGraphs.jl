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

# Essential method for the interface
partitioned_vertices(g::AbstractGraph) = [vertices(g)]

# Don't need to overload this
partitioned_vertices(g::AbstractGraph, sv::SuperVertex) = partitioned_vertices(g)[parent(sv)]
function partitioned_vertices(g::AbstractGraph, svs::Vector{<:SuperVertex}) 
    return mapreduce(sv -> partitioned_vertices(g, sv), vcat, svs)
end

# Optional functions for the interface

## Return the partition that a vertex belongs to
function findpartition(pvs, vertex)
    rv = findfirst(pv -> vertex ∈ pv, pvs)
    if isnothing(rv)
        error("Vertex $vertex not found in any partition.")
    end
    return rv
end
findpartition(g::AbstractGraph, vertex) = findpartition(partitioned_vertices(g), vertex)

function partitioned_edges(g::AbstractGraph, pvs = partitioned_vertices(g))

    SVT = keytype(pvs)
    ET = edgetype(g)
    rv = Dictionary{NamedEdge{SVT}, Vector{ET}}()

    for e in edges(g)
        pv_src = findpartition(pvs, src(e))
        pv_dst = findpartition(pvs, dst(e))
        se = NamedEdge(pv_src => pv_dst)
        if is_self_loop(se)
            continue
        end
        push!(get!(rv, se, typeof(e)[]), e)
    end
    return rv
end
partitioned_edges(g::AbstractGraph, se::AbstractSuperEdge) = partitioned_edges(g)[parent(se)]
function partitioned_edges(g::AbstractGraph, ses::Vector{<:AbstractSuperEdge}) 
    return mapreduce(se -> partitioned_edges(g, se), vcat, ses)
end

quotient_vertices(g) = keys(partitioned_vertices(g))
quotient_edges(g, pvs = partitioned_vertices(g)) = keys(partitioned_edges(g, pvs))

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


"""
abstract type AbstractPartitionedGraph{V, PV} <: AbstractNamedGraph{V}

To use `AbstractPartitionedGraph` one should defined `unpartitioned_graph` that returns
an underlying graph *without* any partitioning. One should also define:
"""
abstract type AbstractPartitionedGraph{V, PV} <: AbstractNamedGraph{V} end

#Needed for interface
unpartitioned_graph(::AbstractPartitionedGraph) = not_implemented()
Base.copy(::AbstractPartitionedGraph) = not_implemented()

super_vertex_type(::Type{<:AbstractPartitionedGraph}) = not_implemented()
super_edge_type(::Type{<:AbstractPartitionedGraph}) = not_implemented()

supervertex(::AbstractPartitionedGraph, vertex) = not_implemented()
superedge(::AbstractPartitionedGraph, edge) = not_implemented()

delete_from_vertex_map!(::AbstractPartitionedGraph, vertex) = not_implemented()
insert_to_vertex_map!(::AbstractPartitionedGraph, vertex) = not_implemented()

function unpartitioned_graph_type(::Type{<:AbstractPartitionedGraph})
    return not_implemented()
end
function GraphsExtensions.directed_graph_type(::Type{<:AbstractPartitionedGraph})
    return not_implemented()
end
function GraphsExtensions.undirected_graph_type(::Type{<:AbstractPartitionedGraph})
    return not_implemented()
end

# Derived (by default)
super_vertex_type(pg::AbstractPartitionedGraph) = super_vertex_type(typeof(pg))
super_edge_type(pg::AbstractPartitionedGraph) = super_edge_type(typeof(pg))

function unpartitioned_graph_type(pg::AbstractPartitionedGraph)
    return typeof(unpartitioned_graph(pg))
end

"""
    supervertices(pg::AbstractPartitionedGraph, vs = vertices(pg))

Return all unique super vertices corresponding to the set vertices `vs` of the graph `pg`.
"""
function supervertices(pg::AbstractPartitionedGraph, vs = vertices(pg))
    return unique(map(v -> supervertex(pg,v), vs))
end

"""
    superedges(pg::AbstractPartitionedGraph, es = edges(pg))

Return all unique super edges corresponding to the set edges `es` of the graph `pg`.
"""
function superedges(pg::AbstractPartitionedGraph, es = edges(pg))
    return filter!(!is_self_loop, unique(map(e -> superedge(pg, e), es)))
end
superedge(pg::AbstractPartitionedGraph, p::Pair) = superedge(pg, edgetype(pg)(p))

# AbstractGraph interface.
function Graphs.is_directed(graph_type::Type{<:AbstractPartitionedGraph})
    return is_directed(unpartitioned_graph_type(graph_type))
end

#Functions for the abstract type
Graphs.vertices(pg::AbstractPartitionedGraph) = vertices(unpartitioned_graph(pg))

"""
    vertices(pg::AbstractPartitionedGraph, supervertex::AbstractSuperEdge)
    vertices(pg::AbstractPartitionedGraph, supervertices::Vector{AbstractSuperEdge})

Return the set of vertices in the partitioned graph `pg` that correspond to the super vertex
`supervertex` or set of super vertices `supervertex`.
"""
function Graphs.vertices(pg::AbstractGraph, supervertex::SuperVertex)
    return partitioned_vertices(pg)[parent(supervertex)]
end
function Graphs.vertices(pg::AbstractPartitionedGraph, supervertices::Vector{<:SuperVertex})
    return unique(reduce(vcat, Iterators.map(sv -> vertices(pg, sv), supervertices)))
end

Graphs.edges(pg::AbstractPartitionedGraph) = edges(unpartitioned_graph(pg))

"""
    edges(pg::AbstractPartitionedGraph, superedge::AbstractSuperEdge)
    edges(pg::AbstractPartitionedGraph, superedges::Vector{AbstractSuperEdge})

Return the set of edges in the partitioned graph `pg` that correspond to the super edge `
superedge` or set of super edges `superedges`.
"""
function Graphs.edges(pg::AbstractPartitionedGraph, superedge::AbstractSuperEdge)
    psrc_vs = vertices(pg, src(superedge))
    pdst_vs = vertices(pg, dst(superedge))
    psrc_subgraph, _ = induced_subgraph(unpartitioned_graph(pg), psrc_vs)
    pdst_subgraph, _ = induced_subgraph(pg, pdst_vs)
    full_subgraph, _ = induced_subgraph(pg, vcat(psrc_vs, pdst_vs))

    return setdiff(edges(full_subgraph), vcat(edges(psrc_subgraph), edges(pdst_subgraph)))
end
function Graphs.edges(pg::AbstractPartitionedGraph, superedges::Vector{<:AbstractSuperEdge})
    return unique(reduce(vcat, [edges(pg, se) for se in superedges]))
end

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

function is_boundary_edge(pg::AbstractPartitionedGraph, edge::AbstractEdge)
    p_edge = superedge(pg, edge)
    return src(p_edge) == dst(p_edge)
end

function Graphs.rem_edge!(pg::AbstractPartitionedGraph, edge::AbstractEdge)
    pg_edge = superedge(pg, edge)
    if has_edge(QuotientView(pg), pg_edge)
        g_edges = edges(pg, pg_edge)
        if length(g_edges) == 1
            rem_edge!(QuotientView(pg), pg_edge)
        end
    end
    return rem_edge!(unpartitioned_graph(pg), edge)
end

#Vertex addition and removal. I think it's important not to allow addition of a vertex without specification of PV
function Graphs.add_vertex!(
        pg::AbstractPartitionedGraph, vertex, supervertex::SuperVertex
    )
    add_vertex!(unpartitioned_graph(pg), vertex)
    add_vertex!(QuotientView(pg), parent(supervertex))
    insert_to_vertex_map!(pg, vertex, supervertex)
    return pg
end

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

function Graphs.rem_vertex!(pg::AbstractPartitionedGraph, vertex::SuperVertex)
    return rem_super_vertex!(pg, vertex)
end
    
Graphs.rem_vertex!(::AbstractPartitionedGraph, vertex) = not_implemented()

function Graphs.add_vertex!(pg::AbstractPartitionedGraph, vertex)
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

function GraphsExtensions.subgraph(
        pg::AbstractPartitionedGraph, supervertex::SuperVertex
    )
    return first(induced_subgraph(unpartitioned_graph(pg), vertices(pg, [supervertex])))
end

function Graphs.induced_subgraph(
        pg::AbstractPartitionedGraph, supervertex::SuperVertex
    )
    return subgraph(pg, supervertex), nothing
end
