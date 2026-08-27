"""
    PartitionedView{V, PV, G, P} <: AbstractPartitionedGraph{V, PV}
    PartitionedView(graph::AbstractGraph, partitioned_vertices)

A lightweight view of the graph `graph` with vertex type `V` as a partitioned
graph, with its vertices partitioned into the quotient vertices of type `PV`
given by `partitioned_vertices`. See [`PartitionedGraph`](@ref) for the accepted
forms of `partitioned_vertices`.

Unlike [`PartitionedGraph`](@ref), this stores nothing beyond `graph` and
`partitioned_vertices`: the quotient graph and the map from each vertex to the
quotient vertex containing it are recomputed from the partitioning on each use.
It is therefore cheap to construct but slower to query at the quotient level.

# Examples

```jldoctest
julia> using Graphs: ne, nv, path_graph

julia> using NamedGraphs: NamedGraph

julia> using NamedGraphs.PartitionedGraphs: PartitionedView, QuotientView

julia> g = NamedGraph(path_graph(4), ["a", "b", "c", "d"]);

julia> pv = PartitionedView(g, [["a", "b"], ["c", "d"]]);

julia> (nv(pv), ne(pv))
(4, 3)

julia> (nv(QuotientView(pv)), ne(QuotientView(pv)))
(2, 1)
```
"""
struct PartitionedView{V, PV, G <: AbstractGraph{V}, P} <: AbstractPartitionedGraph{V, PV}
    graph::G
    partitioned_vertices::P
    function PartitionedView(
            graph::G,
            partitioned_vertices::P
        ) where {V, G <: AbstractGraph{V}, P}
        PV = keytype(partitioned_vertices)
        return new{V, PV, G, P}(graph, partitioned_vertices)
    end
end

unpartitioned_graph(pv::PartitionedView) = getfield(pv, :graph)
partitioned_vertices(pv::PartitionedView) = getfield(pv, :partitioned_vertices)

function unpartitioned_graph_type(graph_type::Type{<:PartitionedView})
    return fieldtype(graph_type, :graph)
end
