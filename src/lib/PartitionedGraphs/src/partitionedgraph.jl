using Dictionaries: Dictionary
using Graphs:
    AbstractEdge, AbstractGraph, add_edge!, edges, has_edge, induced_subgraph, vertices, dst, src, edgetype
using .GraphsExtensions: GraphsExtensions, boundary_edges, is_self_loop, partitions
using ..NamedGraphs: NamedEdge, NamedGraph

# TODO: Parametrize `partitioned_vertices` and `which_partition`,
# see https://github.com/mtfishman/NamedGraphs.jl/issues/63.
struct PartitionedGraph{V, PV, G <: AbstractGraph{V}, NV} <: AbstractPartitionedGraph{V, PV}
    graph::G
    quotient_graph::NamedGraph{PV}
    partitioned_vertices::Dictionary{PV, Vector{NV}}
    which_partition::Dictionary{V, PV}
end

partitioned_vertices(pg::PartitionedGraph) = pg.partitioned_vertices

quotient_graph(pg::PartitionedGraph) = pg.quotient_graph
quotient_edges(pg::PartitionedGraph) = edges(pg.quotient_graph)
quotient_vertices(pg::PartitionedGraph) = vertices(pg.quotient_graph)

super_vertex_type(::Type{<:PartitionedGraph{V}}) where {V} = SuperVertex{V}
super_edge_type(G::Type{<:PartitionedGraph{V}}) where {V} = SuperEdge{V, edgetype(G)}

Graphs.edgetype(::Type{<:PartitionedGraph{V,PV,G}}) where {V,PV,G} = edgetype(G)

##Constructors.
function PartitionedGraph(g::AbstractGraph{V}, partitioned_vertices) where {V}
    pvs = keys(partitioned_vertices)
    qg = NamedGraph(pvs)
    which_partition = Dictionary{V, eltype(pvs)}()
    for v in vertices(g)
        v_pvs = Set(findall(pv -> v ∈ partitioned_vertices[pv], pvs))
        @assert length(v_pvs) == 1
        insert!(which_partition, v, first(v_pvs))
    end
    for e in edges(g)
        pv_src, pv_dst = which_partition[src(e)], which_partition[dst(e)]
        pe = NamedEdge(pv_src => pv_dst)
        if pv_src != pv_dst && !has_edge(qg, pe)
            add_edge!(qg, pe)
        end
    end
    return PartitionedGraph(
        g,
        qg,
        map(v -> [v;], Dictionary(partitioned_vertices)),
        which_partition
    )
end

function PartitionedGraph(partitioned_vertices)
    return PartitionedGraph(NamedGraph(keys(partitioned_vertices)), partitioned_vertices)
end

function PartitionedGraph(g::AbstractGraph; kwargs...)
    partitioned_verts = partitions(g; kwargs...)
    return PartitionedGraph(g, partitioned_verts)
end

#Needed for interface
unpartitioned_graph(pg::PartitionedGraph) = getfield(pg, :graph)
function unpartitioned_graph_type(graph_type::Type{<:PartitionedGraph})
    return fieldtype(graph_type, :graph)
end
findpartition(pg::PartitionedGraph, vertex) = pg.which_partition[vertex]

function supervertex(pg::PartitionedGraph, vertex)
    return SuperVertex(findpartition(pg, vertex))
end

supervertices(pg::PartitionedGraph) = SuperVertex.(vertices(quotient_graph(pg)))

function superedge(pg::PartitionedGraph, edge::AbstractEdge)
    return SuperEdge(
        parent(supervertex(pg, src(edge))) => parent(supervertex(pg, dst(edge)))
    )
end

superedges(pg::PartitionedGraph) = map(SuperEdge, edges(QuotientView(pg)))

function boundary_superedges(pg::PartitionedGraph, supervertices; kwargs...)
    return SuperEdge.(
        boundary_edges(quotient_graph(pg), parent.(supervertices); kwargs...)
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
        copy(quotient_graph(pg)),
        copy(partitioned_vertices(pg)),
        copy(pg.which_partition),
    )
end

function insert_to_vertex_map!(
        pg::PartitionedGraph, vertex, supervertex::SuperVertex
    )
    pv = parent(supervertex)

    push!(get!(pg.partitioned_vertices, pv, []), vertex)
    unique!(pg.partitioned_vertices[pv])

    insert!(pg.which_partition, vertex, pv)

    return pg
end

function delete_from_vertex_map!(pg::PartitionedGraph{V}, vertex::V) where {V}
    sv = supervertex(pg, vertex)
    return delete_from_vertex_map!(pg, sv, vertex)
end

function delete_from_vertex_map!(
    pg::PartitionedGraph{V}, partitioned_vertex::SuperVertex, vertex::V
) where {V}
    vs = vertices(pg, partitioned_vertex)

    delete!(pg.partitioned_vertices, parent(partitioned_vertex))

    if length(vs) != 1
        insert!(pg.partitioned_vertices, parent(partitioned_vertex), setdiff(vs, [vertex]))
    end

    delete!(pg.which_partition, vertex)
    return partitioned_vertex
end

function Graphs.rem_vertex!(pg::PartitionedGraph{V}, vertex::V) where {V}
    sv = supervertex(pg, vertex)

    delete_from_vertex_map!(pg, sv, vertex)

    rem_vertex!(unpartitioned_graph(pg), vertex)

    if !haskey(partitioned_vertices(pg), parent(sv))
        rem_vertex!(pg.quotient_graph, parent(sv))
    end

    return pg
end

function Graphs.add_vertex!(pg::PartitionedGraph{V}, vertex::V, sv::SuperVertex) where {V}
    add_vertex!(pg.graph, vertex)
    add_vertex!(pg.quotient_graph, parent(sv))
    insert_to_vertex_map!(pg, vertex, sv)
    return pg
end

function Graphs.add_edge!(pg::PartitionedGraph, edge)
    @assert edge isa edgetype(pg)
    add_edge!(pg.graph, edge)
    pg_edge = parent(superedge(pg, edge))
    if src(pg_edge) != dst(pg_edge)
        add_edge!(pg.quotient_graph, pg_edge)
    end
    return pg
end

### PartitionedGraph Specific Functions
function partitionedgraph_induced_subgraph(pg::PartitionedGraph, vertices::Vector)
    sub_pg_graph, _ = induced_subgraph(unpartitioned_graph(pg), vertices)
    sub_partitioned_vertices = copy(partitioned_vertices(pg))
    for pv in NamedGraphs.vertices(QuotientView(pg))
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
