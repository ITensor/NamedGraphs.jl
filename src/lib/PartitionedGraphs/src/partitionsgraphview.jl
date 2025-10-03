struct PartitionsGraphView{V, G <: AbstractGraph{V}} <: AbstractNamedGraph{V}
    graph::G
end

Base.copy(g::PartitionsGraphView) = PartitionsGraphView(copy(g.graph))

using Graphs: AbstractGraph
partitions_graph(g::AbstractGraph) = PartitionsGraphView(PartitionedGraph(g, [vertices(g)]))

# Graphs.jl and NamedGraphs.jl interface overloads for `PartitionsGraphView` wrapping
# a `PartitionedGraph`.
function NamedGraphs.position_graph_type(
        type::Type{<:PartitionsGraphView{V, G}}
    ) where {V, G <: PartitionedGraph{V}}
    return fieldtype(fieldtype(fieldtype(type, :graph), :partitions_graph), :position_graph)
end
for f in [
        :(Graphs.add_vertex!),
        :(Graphs.edges),
        :(Graphs.vertices),
        :(Graphs.rem_vertex!),
        :(NamedGraphs.edgetype),
        :(NamedGraphs.namedgraph_induced_subgraph),
        :(NamedGraphs.ordered_vertices),
        :(NamedGraphs.position_graph),
        :(NamedGraphs.vertex_positions),
        :(NamedGraphs.vertextype),
    ]
    @eval begin
        function $f(
                g::PartitionsGraphView{V, G}, args...; kwargs...
            ) where {V, G <: PartitionedGraph{V}}
            return $f(g.graph.partitions_graph, args...; kwargs...)
        end
    end
end
