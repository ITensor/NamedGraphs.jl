struct PartitionsGraphView{V,PG<:AbstractGraph{V}} <: AbstractNamedGraph{V}
  partitioned_graph::PG
end

Base.copy(pgv::PartitionsGraphView) = PartitionsGraphView(copy(pgv.partitioned_graph))
partitions_graph(pgv::PartitionsGraphView) = partitions_graph(pgv.partitioned_graph)

# AbstractNamedGraph required interface.
function NamedGraphs.position_graph_type(type::Type{<:PartitionsGraphView})
  return fieldtype(
    fieldtype(fieldtype(type, :partitioned_graph), :partitions_graph), :position_graph
  )
end

#Functionality needed to overload most graphs functions onto the partitioned_graph
for f in [
  :(Graphs.vertices),
  :(Graphs.edges),
  :(NamedGraphs.position_graph),
  :(NamedGraphs.vertex_positions),
  :(NamedGraphs.ordered_vertices),
  :(NamedGraphs.edgetype),
  :(NamedGraphs.vertextype),
]
  @eval begin
    function $f(pgv::PartitionsGraphView, args...; kwargs...)
      return $f(partitions_graph(pgv), args...; kwargs...)
    end
  end
end
