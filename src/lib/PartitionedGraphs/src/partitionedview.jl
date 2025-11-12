using ..OrderedDictionaries: OrderedIndices

struct PartitionedView{V, PV, G <: AbstractGraph{V}, P} <: AbstractPartitionedGraph{V, PV}
    graph::G
    partitioned_vertices::P
    function PartitionedView(graph::G, partitioned_vertices::P) where {V, G <: AbstractGraph{V}, P}
        PV = keytype(partitioned_vertices)
        return new{V, PV, G, P}(graph, partitioned_vertices)
    end
end

unpartitioned_graph(pv::PartitionedView) = getfield(pv, :graph)
partitioned_vertices(pv::PartitionedView) = getfield(pv, :partitioned_vertices)
