using ..NamedGraphs.GraphsExtensions: GraphsExtensions, boundary_edges, directed_graph_type,
    is_self_loop, partition_vertices, undirected_graph_type, vertextype
using ..NamedGraphs: NamedEdge, NamedGraph, NamedGraphs
using Dictionaries: Dictionary
using Graphs: AbstractEdge, AbstractGraph, add_edge!, dst, edges, edgetype, has_edge,
    induced_subgraph, src, vertices

# TODO: Parametrize `partitioned_vertices` and `which_partition`,
# see https://github.com/mtfishman/NamedGraphs.jl/issues/63.
"""
    PartitionedGraph{V, PV, G, QG, P} <: AbstractPartitionedGraph{V, PV}
    PartitionedGraph(graph::AbstractGraph, partitioned_vertices)
    PartitionedGraph(partitioned_vertices)
    PartitionedGraph(graph::AbstractGraph; kwargs...)

A graph `graph` with vertex type `V` together with a partitioning of its
vertices into quotient vertices of type `PV`. In addition to the graph and the
partitioning, it caches the quotient graph and the map from each vertex to the
quotient vertex containing it, so that quotient level queries such as
[`quotientvertices`](@ref) and [`has_quotientedge`](@ref) do not have to search
through the partitioning. Use [`PartitionedView`](@ref) instead when that extra
storage is not wanted.

`partitioned_vertices` maps each quotient vertex to the vertices of `graph` it
contains. It can be a `Dictionaries.Dictionary` or a `Dict`, whose keys are the
quotient vertices, or a vector of vertex collections, in which case the quotient
vertices are the indices `1:length(partitioned_vertices)`. Every vertex of
`graph` must be contained in exactly one quotient vertex.

Passing `partitioned_vertices` on its own gives the discrete partitioning of a
graph with no edges: every vertex sits in its own quotient vertex, as in
`PartitionedGraph(1:4)`. It requires each key of `partitioned_vertices` to be a
member of its own value, since the vertices are taken from
`keys(partitioned_vertices)` while the partition memberships come from the
values, and it errors otherwise. Passing `graph` on its own instead
partitions its vertices automatically with
`GraphsExtensions.partition_vertices`, which the keyword arguments are forwarded
to: it needs either `npartitions` or `nvertices_per_partition`, and a
partitioning backend such as Metis.jl or KaHyPar.jl to be loaded.

# Examples

```jldoctest
julia> using Graphs: ne, nv, path_graph, vertices

julia> using NamedGraphs: NamedGraph

julia> using NamedGraphs.PartitionedGraphs: PartitionedGraph, QuotientVertex, QuotientView

julia> g = NamedGraph(path_graph(4), ["a", "b", "c", "d"]);

julia> pg = PartitionedGraph(g, [["a", "b"], ["c", "d"]]);

julia> (nv(pg), ne(pg))
(4, 3)

julia> vertices(pg, QuotientVertex(1))
2-element Vector{String}:
 "a"
 "b"

julia> (nv(QuotientView(pg)), ne(QuotientView(pg)))
(2, 1)
```
"""
struct PartitionedGraph{
        V, PV, G <: AbstractGraph{V}, QG <: AbstractGraph{PV}, P <: Dictionary,
    } <: AbstractPartitionedGraph{V, PV}
    graph::G
    quotient_graph::QG
    partitioned_vertices::P
    which_partition::Dictionary{V, PV}
end

"""
    partitionedgraph(graph::AbstractGraph, partitioned_vertices) -> PartitionedGraph

Partition the vertices of `graph` into the quotient vertices given by
`partitioned_vertices`, returning a [`PartitionedGraph`](@ref). See
[`PartitionedGraph`](@ref) for the accepted forms of `partitioned_vertices`.

`graph` may itself be a partitioned graph, in which case the result has two
layers of partitioning, which can be removed again with
[`departition`](@ref) and [`unpartition`](@ref).

# Examples

```jldoctest
julia> using Graphs: ne, nv, path_graph

julia> using NamedGraphs: NamedGraph

julia> using NamedGraphs.PartitionedGraphs: QuotientView, partitionedgraph

julia> g = NamedGraph(path_graph(4), ["a", "b", "c", "d"]);

julia> pg = partitionedgraph(g, [["a", "b"], ["c", "d"]]);

julia> (nv(pg), ne(pg))
(4, 3)

julia> (nv(QuotientView(pg)), ne(QuotientView(pg)))
(2, 1)
```
"""
partitionedgraph(g::AbstractGraph, partition) = PartitionedGraph(g, partition)

# Interface overloads
partitioned_vertices(pg::PartitionedGraph) = pg.partitioned_vertices
quotient_graph(pg::PartitionedGraph) = pg.quotient_graph
quotientvertex(pg::PartitionedGraph, vertex) = QuotientVertex(pg.which_partition[vertex])

Graphs.edgetype(::Type{<:PartitionedGraph{V, PV, G}}) where {V, PV, G} = edgetype(G)
Graphs.is_directed(::Type{<:PartitionedGraph{V, PV, G}}) where {V, PV, G} = is_directed(G)

##Constructors.
function PartitionedGraph(g::AbstractGraph, partitioned_vertices::Dict)
    return PartitionedGraph(g, Dictionary(partitioned_vertices))
end

function PartitionedGraph(g::AbstractGraph, partitioned_vertices::AbstractVector)
    return PartitionedGraph(g, Dictionary(partitioned_vertices))
end

function PartitionedGraph(g::AbstractGraph, partitioned_vertices::Dictionary)
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
        partitioned_vertices,
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
        copy(pg.which_partition)
    )
end

function insert_to_vertex_map!(pg::PartitionedGraph, vertex, quotientvertex)
    push!(get!(pg.partitioned_vertices, quotientvertex, []), vertex)
    unique!(pg.partitioned_vertices[quotientvertex])

    insert!(pg.which_partition, vertex, quotientvertex)

    return pg
end

function delete_from_vertex_map!(pg::PartitionedGraph{V}, vertex::V) where {V}
    sv = quotientvertex(pg, vertex)
    return delete_from_vertex_map!(pg, sv, vertex)
end

function delete_from_vertex_map!(
        pg::PartitionedGraph{V}, quotientvertex, vertex::V
    ) where {V}
    return delete_from_vertex_map!(pg, quotientvertex, vertex)
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
    has_vertex(pg, vertex) || return false
    qv = parent(quotientvertex(pg, vertex))

    delete_from_vertex_map!(pg, qv, vertex)

    rem_vertex!(pg.graph, vertex)

    # If the super-vertex is now empty, remove it from the quotient graph
    qv ∈ keys(pg.partitioned_vertices) || rem_vertex!(pg.quotient_graph, qv)

    return true
end

# Interface function
function add_subquotientvertex!(pg::PartitionedGraph{V}, qv, vertex) where {V}
    add_vertex!(pg.graph, vertex) || return false
    add_vertex!(pg.quotient_graph, qv)
    insert_to_vertex_map!(pg, vertex, qv)
    return true
end

function Graphs.add_edge!(pg::PartitionedGraph, edge::AbstractEdge)
    @assert edge isa edgetype(pg)
    add_edge!(pg.graph, edge) || return false
    pg_edge = parent(quotientedge(pg, edge))
    if src(pg_edge) != dst(pg_edge)
        add_edge!(pg.quotient_graph, pg_edge)
    end
    return true
end

function Graphs.rem_edge!(pg::PartitionedGraph, edge::AbstractEdge)
    @assert edge isa edgetype(pg)
    has_edge(pg, edge) || return false
    se = quotientedge(pg, edge)
    if se in quotientedges(pg) || reverse(se) in quotientedges(pg)
        g_edges = edges(pg, se)
        if length(g_edges) == 1
            # This is the last edge between these partitions, so also remove the super-edge.
            rem_edge!(pg.quotient_graph, parent(se))
        end
    end
    # Always remove the underlying edge itself.
    return rem_edge!(pg.graph, edge)
end

## Case where we preserve partitioning.

NamedGraphs.to_vertices(::PartitionedGraph, qvsvs::QuotientVerticesVertices) = qvsvs

function NamedGraphs.induced_subgraph_from_vertices(
        pg::PartitionedGraph, subvertices::QuotientVerticesVertices
    )
    sub_pg_graph, _ = induced_subgraph(pg.graph, subvertices)
    sub_partitioned_vertices = copy(pg.partitioned_vertices)

    for qv in quotientvertices(pg)
        pv = parent(qv)

        vs = intersect(QuotientVertexSlice(subvertices), sub_partitioned_vertices[pv])
        if !isempty(vs)
            sub_partitioned_vertices[pv] = vs
        else
            k = keys(sub_partitioned_vertices)
            delete!(sub_partitioned_vertices, pv)
        end
    end

    return PartitionedGraph(sub_pg_graph, sub_partitioned_vertices), nothing
end

function GraphsExtensions.undirected_graph(g::PartitionedGraph)
    dg = GraphsExtensions.undirected_graph(unpartitioned_graph(g))
    return PartitionedGraph(dg, partitioned_vertices(g))
end
function GraphsExtensions.directed_graph(g::PartitionedGraph)
    dg = GraphsExtensions.directed_graph(unpartitioned_graph(g))
    return PartitionedGraph(dg, partitioned_vertices(g))
end
function GraphsExtensions.undirected_graph_type(
        type::Type{<:PartitionedGraph{V, PV}}
    ) where {V, PV}
    UG = undirected_graph_type(unpartitioned_graph_type(type))
    QG = undirected_graph_type(quotient_graph_type(type))
    P = fieldtype(type, :partitioned_vertices)
    return PartitionedGraph{V, PV, UG, QG, P}
end
function GraphsExtensions.directed_graph_type(
        type::Type{<:PartitionedGraph{V, PV}}
    ) where {V, PV}
    DG = directed_graph_type(unpartitioned_graph_type(type))
    QG = directed_graph_type(quotient_graph_type(type))
    P = fieldtype(type, :partitioned_vertices)
    return PartitionedGraph{V, PV, DG, QG, P}
end
