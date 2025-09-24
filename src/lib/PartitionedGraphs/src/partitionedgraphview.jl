struct PartitionedGraphView{V,PG<:AbstractGraph{V}} <: AbstractGraph{V}
  value::PG
end

value(pgv::PartitionedGraphView) = pgv.value
Base.copy(pgv::PartitionedGraphView) = PartitionedGraphView(copy(value(pgv)))
PartitionedGraph(pgv::PartitionedGraphView) = value(pgv)

#Functionality that behaves differently
for f in [
  :(Graphs.vertices),
  :(Graphs.edges),
  :(Graphs.induced_subgraph),
  :(Graphs.neighbors),
  :(Graphs.degree),
  :(Graphs.is_tree),
  :(Graphs.is_connected),
  :(Graphs.connected_components),
  :(Graphs.is_cyclic),
  :(NamedGraphs.GraphsExtensions.boundary_edges),
]
  @eval begin
    function $f(pgv::PartitionedGraphView, args...; kwargs...)
      return $f(partitioned_graph(PartitionedGraph(pgv)), args...; kwargs...)
    end
  end
end

#Functionality that behaves the same
for f in [:unpartitioned_graph]
  @eval begin
    function $f(pgv::PartitionedGraphView, args...; kwargs...)
      return $f(PartitionedGraph(pgv), args...; kwargs...)
    end
  end
end
