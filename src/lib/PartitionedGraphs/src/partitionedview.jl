using ..OrderedDictionaries: OrderedIndices

struct PartitionedView{V, PV, G <: AbstractGraph{V}} <: AbstractPartitionedGraph{V, PV}
    graph::G
    partitioned_vertices::Dictionary{PV, Vector{V}}
end

PartitionedView(g, parts) = PartitionedView(g, to_partitioned_vertices(parts))

# Entry point
to_partitioned_vertices(pvs) = to_partitioned_vertices(eltype(pvs), pvs)

to_partitioned_vertices(::Type, pvs) = to_partitioned_vertices(map(v -> [v;], pvs))
function to_partitioned_vertices(::Type{<:OrderedIndices}, pvs)
    iter_of_vecs = map(pvs) do oi
        rv = Vector{eltype(oi)}(undef, length(oi))
        copyto!(rv, oi)
        return rv
    end
    return to_partitioned_vertices(iter_of_vecs)
end

# Exit point
to_partitioned_vertices(::Type{<:Vector}, pvs) = Dictionary(pvs)

unpartitioned_graph(pv::PartitionedView) = getfield(pv, :graph)
partitioned_vertices(pv::PartitionedView) = getfield(pv, :partitioned_vertices)
