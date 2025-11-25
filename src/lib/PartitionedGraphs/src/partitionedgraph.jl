using Dictionaries: Dictionary
using Graphs:
    AbstractEdge, AbstractGraph, add_edge!, edges, has_edge, induced_subgraph, vertices, dst, src, edgetype
using ..NamedGraphs: NamedGraphs, NamedEdge, NamedGraph
using ..NamedGraphs.GraphsExtensions: GraphsExtensions, boundary_edges, is_self_loop, partition_vertices, directed_graph_type, undirected_graph_type
using ..NamedGraphs.OrderedDictionaries: OrderedDictionary

# TODO: Parametrize `partitioned_vertices` and `which_partition`,
# see https://github.com/mtfishman/NamedGraphs.jl/issues/63.
struct PartitionedGraph{V, PV, G <: AbstractGraph{V}, P <: Dictionary} <: AbstractPartitionedGraph{V, PV}
    graph::G
    quotient_graph::NamedGraph{PV}
    partitioned_vertices::P
    which_partition::Dictionary{V, PV}
end

partitionedgraph(g::AbstractGraph, partition) = PartitionedGraph(g, partition)

# Interface overloads
partitioned_vertices(pg::PartitionedGraph) = pg.partitioned_vertices
quotient_graph(pg::PartitionedGraph) = pg.quotient_graph
quotientvertex(pg::PartitionedGraph, vertex) = QuotientVertex(pg.which_partition[vertex])

Graphs.edgetype(::Type{<:PartitionedGraph{V, PV, G}}) where {V, PV, G} = edgetype(G)

##Constructors.
function PartitionedGraph(g::AbstractGraph, partitioned_vertices)
    pvs = keys(partitioned_vertices)
    which_partition = Dictionary{vertextype(g), eltype(pvs)}()
    for v in vertices(g)
        v_pvs = Set(findall(pv -> v ∈ pv, partitioned_vertices))
        @assert length(v_pvs) == 1
        insert!(which_partition, v, first(v_pvs))
    end
    qg = quotient_graph(PartitionedView(g, partitioned_vertices))
    return PartitionedGraph(
        g,
        qg,
        Dictionary(partitioned_vertices),
        which_partition
    )
end

function PartitionedGraph(partitioned_vertices)
    return PartitionedGraph(NamedGraph(keys(partitioned_vertices)), partitioned_vertices)
end

function PartitionedGraph(g::AbstractGraph; kwargs...)
    partitioned_verts = partition_vertices(g; kwargs...)
    return PartitionedGraph(g, partitioned_verts)
end


#Needed for interface
unpartitioned_graph(pg::PartitionedGraph) = getfield(pg, :graph)
function unpartitioned_graph_type(graph_type::Type{<:PartitionedGraph})
    return fieldtype(graph_type, :graph)
end

function Base.copy(pg::PartitionedGraph)
    return PartitionedGraph(
        copy(pg.graph),
        copy(pg.quotient_graph),
        copy(pg.partitioned_vertices),
        copy(pg.which_partition),
    )
end

function insert_to_vertex_map!(
        pg::PartitionedGraph, vertex, quotientvertex::QuotientVertex
    )
    pv = parent(quotientvertex)

    push!(get!(pg.partitioned_vertices, pv, []), vertex)
    unique!(pg.partitioned_vertices[pv])

    insert!(pg.which_partition, vertex, pv)

    return pg
end

function delete_from_vertex_map!(pg::PartitionedGraph{V}, vertex::V) where {V}
    sv = quotientvertex(pg, vertex)
    return delete_from_vertex_map!(pg, sv, vertex)
end

function delete_from_vertex_map!(
        pg::PartitionedGraph{V}, sv::QuotientVertex, vertex::V
    ) where {V}
    return delete_from_vertex_map!(pg, parent(sv), vertex)
end

function delete_from_vertex_map!(
        pg::PartitionedGraph{V, PV}, qv::PV, vertex::V
    ) where {V, PV}

    vs = partitioned_vertices(pg)[qv]

    delete!(pg.partitioned_vertices, qv)

    if length(vs) != 1
        insert!(pg.partitioned_vertices, qv, setdiff(vs, [vertex]))
    end

    delete!(pg.which_partition, vertex)
    return pg
end

function Graphs.rem_vertex!(pg::PartitionedGraph{V}, vertex::V) where {V}
    qv = parent(quotientvertex(pg, vertex))

    delete_from_vertex_map!(pg, qv, vertex)

    rem_vertex!(pg.graph, vertex)

    # If the super-vertex is now empty, remove it from the quotient graph
    if !haskey(pg.partitioned_vertices, qv)
        rem_vertex!(pg.quotient_graph, qv)
    end

    return pg
end

# Interface function
function add_subquotientvertex!(pg::PartitionedGraph{V}, sv::QuotientVertex, vertex::V) where {V}
    add_vertex!(pg.graph, vertex)
    add_vertex!(pg.quotient_graph, parent(sv))
    insert_to_vertex_map!(pg, vertex, sv)
    return pg
end

function Graphs.add_edge!(pg::PartitionedGraph, edge::AbstractEdge)
    @assert edge isa edgetype(pg)
    add_edge!(pg.graph, edge)
    pg_edge = parent(quotientedge(pg, edge))
    if src(pg_edge) != dst(pg_edge)
        add_edge!(pg.quotient_graph, pg_edge)
    end
    return pg
end

function Graphs.rem_edge!(pg::PartitionedGraph, edge::AbstractEdge)
    @assert edge isa edgetype(pg)
    # This already checks if the edge is in pg
    se = quotientedge(pg, edge)
    if se in quotientedges(pg) || reverse(se) in quotientedges(pg)
        g_edges = edges(pg, se)
        if length(g_edges) == 1
            # Remove the entire super-edge
            return rem_edge!(pg.quotient_graph, parent(se))
        end
    end
    return rem_edge!(pg.graph, edge)
end

### PartitionedGraph Specific Functions
function NamedGraphs.induced_subgraph_from_vertices(pg::PartitionedGraph, subvertices)
    sub_pg_graph, _ = induced_subgraph(pg.graph, subvertices)
    sub_partitioned_vertices = copy(pg.partitioned_vertices)
    for qv in quotientvertices(pg)
        pv = parent(qv)

        vs = intersect(subvertices, sub_partitioned_vertices[pv])
        if !isempty(vs)
            sub_partitioned_vertices[pv] = vs
        else
            delete!(sub_partitioned_vertices, pv)
        end
    end

    return PartitionedGraph(sub_pg_graph, sub_partitioned_vertices), nothing
end
function NamedGraphs.induced_subgraph_from_vertices(
        pg::PartitionedGraph, subvertices::SubVertices{<:QuotientVertex}
    )
    sg, vs = NamedGraphs.induced_subgraph_from_vertices(pg, subvertices.vertices)
    return unpartitioned_graph(sg), vs
end


function GraphsExtensions.directed_graph_type(type::Type{<:PartitionedGraph})
    return directed_graph_type(unpartitioned_graph_type(type))
end
function GraphsExtensions.undirected_graph_type(type::Type{<:PartitionedGraph})
    return undirected_graph_type(unpartitioned_graph_type(type))
end
