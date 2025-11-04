using Dictionaries: Dictionary
using Graphs:
    AbstractEdge, AbstractGraph, add_edge!, edges, has_edge, induced_subgraph, vertices
using .GraphsExtensions:
    GraphsExtensions, boundary_edges, is_self_loop, partitioned_vertices
using ..NamedGraphs: NamedEdge, NamedGraph

# TODO: Parametrize `partitioned_vertices` and `which_partition`,
# see https://github.com/mtfishman/NamedGraphs.jl/issues/63.
struct PartitionedGraph{V, PV, G <: AbstractGraph{V}, PG <: AbstractGraph{PV}} <:
    AbstractPartitionedGraph{V, PV}
    graph::G
    partitions_graph::PG
    partitioned_vertices::Dictionary
    which_partition::Dictionary
end

##Constructors.
function PartitionedGraph(g::AbstractGraph, partitioned_vertices)
    pvs = keys(partitioned_vertices)
    pg = NamedGraph(pvs)
    # TODO: Make this type more specific.
    which_partition = Dictionary()
    for v in vertices(g)
        v_pvs = Set(findall(pv -> v ∈ partitioned_vertices[pv], pvs))
        @assert length(v_pvs) == 1
        insert!(which_partition, v, first(v_pvs))
    end
    for e in edges(g)
        pv_src, pv_dst = which_partition[src(e)], which_partition[dst(e)]
        pe = NamedEdge(pv_src => pv_dst)
        if pv_src != pv_dst && !has_edge(pg, pe)
            add_edge!(pg, pe)
        end
    end
    return PartitionedGraph(g, pg, Dictionary(partitioned_vertices), which_partition)
end

function PartitionedGraph(partitioned_vertices)
    return PartitionedGraph(NamedGraph(keys(partitioned_vertices)), partitioned_vertices)
end

function PartitionedGraph(g::AbstractGraph; kwargs...)
    partitioned_verts = partitioned_vertices(g; kwargs...)
    return PartitionedGraph(g, partitioned_verts)
end

#Needed for interface
unpartitioned_graph(pg::PartitionedGraph) = getfield(pg, :graph)
function unpartitioned_graph_type(graph_type::Type{<:PartitionedGraph})
    return fieldtype(graph_type, :graph)
end
function GraphsExtensions.partitioned_vertices(pg::PartitionedGraph)
    return getfield(pg, :partitioned_vertices)
end
which_partition(pg::PartitionedGraph) = getfield(pg, :which_partition)
function Graphs.vertices(pg::PartitionedGraph, supervertex::SuperVertex)
    return partitioned_vertices(pg)[parent(supervertex)]
end
function Graphs.vertices(pg::PartitionedGraph, supervertices::Vector{<:SuperVertex})
    return unique(reduce(vcat, Iterators.map(sv -> vertices(pg, sv), supervertices)))
end
function supervertex(pg::PartitionedGraph, vertex)
    return SuperVertex(which_partition(pg)[vertex])
end

function supervertices(pg::PartitionedGraph, verts)
    return unique(supervertex(pg, v) for v in verts)
end

function supervertices(pg::PartitionedGraph)
    return SuperVertex.(vertices(pg.partitions_graph))
end

function superedge(pg::PartitionedGraph, edge::AbstractEdge)
    return SuperEdge(
        parent(supervertex(pg, src(edge))) => parent(supervertex(pg, dst(edge)))
    )
end

superedge(pg::PartitionedGraph, p::Pair) = superedge(pg, edgetype(pg)(p))

function superedges(pg::PartitionedGraph, edges::Vector)
    return filter(!is_self_loop, unique([superedge(pg, e) for e in edges]))
end

function superedges(pg::PartitionedGraph)
    return SuperEdge.(edges(pg.partitions_graph))
end

function Graphs.edges(pg::PartitionedGraph, superedge::SuperEdge)
    psrc_vs = vertices(pg, src(superedge))
    pdst_vs = vertices(pg, dst(superedge))
    psrc_subgraph, _ = induced_subgraph(unpartitioned_graph(pg), psrc_vs)
    pdst_subgraph, _ = induced_subgraph(pg, pdst_vs)
    full_subgraph, _ = induced_subgraph(pg, vcat(psrc_vs, pdst_vs))

    return setdiff(edges(full_subgraph), vcat(edges(psrc_subgraph), edges(pdst_subgraph)))
end

function Graphs.edges(pg::PartitionedGraph, superedges::Vector{<:SuperEdge})
    return unique(reduce(vcat, [edges(pg, se) for se in superedges]))
end

function boundary_superedges(pg::PartitionedGraph, supervertices; kwargs...)
    return SuperEdge.(
        boundary_edges(pg.partitions_graph, parent.(supervertices); kwargs...)
    )
end

function boundary_superedges(
        pg::PartitionedGraph, supervertex::SuperVertex; kwargs...
    )
    return boundary_superedges(pg, [supervertex]; kwargs...)
end

function Base.copy(pg::PartitionedGraph)
    return PartitionedGraph(
        copy(unpartitioned_graph(pg)),
        copy(pg.partitions_graph),
        copy(partitioned_vertices(pg)),
        copy(which_partition(pg)),
    )
end

function insert_to_vertex_map!(
        pg::PartitionedGraph, vertex, supervertex::SuperVertex
    )
    pv = parent(supervertex)
    if pv ∉ keys(partitioned_vertices(pg))
        insert!(partitioned_vertices(pg), pv, [vertex])
    else
        partitioned_vertices(pg)[pv] = unique(vcat(vertices(pg, supervertex), [vertex]))
    end

    insert!(which_partition(pg), vertex, pv)
    return pg
end

function delete_from_vertex_map!(pg::PartitionedGraph, vertex)
    sv = supervertex(pg, vertex)
    return delete_from_vertex_map!(pg, sv, vertex)
end

function delete_from_vertex_map!(
        pg::PartitionedGraph, partitioned_vertex::SuperVertex, vertex
    )
    vs = vertices(pg, partitioned_vertex)
    delete!(partitioned_vertices(pg), parent(partitioned_vertex))
    if length(vs) != 1
        insert!(partitioned_vertices(pg), parent(partitioned_vertex), setdiff(vs, [vertex]))
    end

    delete!(which_partition(pg), vertex)
    return partitioned_vertex
end

### PartitionedGraph Specific Functions
function partitionedgraph_induced_subgraph(pg::PartitionedGraph, vertices::Vector)
    sub_pg_graph, _ = induced_subgraph(unpartitioned_graph(pg), vertices)
    sub_partitioned_vertices = copy(partitioned_vertices(pg))
    for pv in NamedGraphs.vertices(pg.partitions_graph)
        vs = intersect(vertices, sub_partitioned_vertices[pv])
        if !isempty(vs)
            sub_partitioned_vertices[pv] = vs
        else
            delete!(sub_partitioned_vertices, pv)
        end
    end

    return PartitionedGraph(sub_pg_graph, sub_partitioned_vertices), nothing
end

function partitionedgraph_induced_subgraph(
        pg::PartitionedGraph, supervertices::Vector{<:SuperVertex}
    )
    return induced_subgraph(pg, vertices(pg, supervertices))
end

function Graphs.induced_subgraph(pg::PartitionedGraph, vertices)
    return partitionedgraph_induced_subgraph(pg, vertices)
end

# Fixes ambiguity error with `Graphs.jl`.
function Graphs.induced_subgraph(pg::PartitionedGraph, vertices::Vector{<:Integer})
    return partitionedgraph_induced_subgraph(pg, vertices)
end
