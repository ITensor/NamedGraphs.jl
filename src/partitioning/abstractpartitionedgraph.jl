abstract type AbstractPartitionedGraph{V,PV} <: AbstractNamedGraph{V} end

#Needed for interface
partitioned_graph(pg::AbstractPartitionedGraph) = not_implemented()
graph(pg::AbstractPartitionedGraph) = not_implemented()
partition_vertices(pg::AbstractPartitionedGraph, partition_vertex) = not_implemented()
partition_vertex(pg::AbstractPartitionedGraph, vertex) = not_implemented()
copy(pg::AbstractPartitionedGraph) = not_implemented()
function add_to_vertex_map!(pg::AbstractPartitionedGraph, vertex, partition_vertex)
  return not_implemented()
end
rem_from_vertex_map!(pg::AbstractPartitionedGraph, vertex) = not_implemented()

vertices(pg::AbstractPartitionedGraph) = vertices(graph(pg))
parent_graph(pg::AbstractPartitionedGraph) = parent_graph(graph(pg))
function vertex_to_parent_vertex(pg::AbstractPartitionedGraph, vertex)
  return vertex_to_parent_vertex(graph(pg), vertex)
end
edgetype(pg::AbstractPartitionedGraph) = edgetype(graph(pg))
function parent_graph_type(G::Type{<:AbstractPartitionedGraph})
  return fieldtype(fieldtype(G, :graph), :parent_graph)
end
directed_graph(G::Type{<:AbstractPartitionedGraph}) = directed_graph(fieldtype(G, :graph))
function undirected_graph(G::Type{<:AbstractPartitionedGraph})
  return unddirected_graph(fieldtype(G, :graph))
end
function has_vertex(pg::AbstractPartitionedGraph, pv::AbstractPartitionVertex)
  return has_vertex(partitioned_graph(pg), underlying_vertex(pv))
end
function has_edge(pg::AbstractPartitionedGraph, pe::AbstractPartitionEdge)
  return has_edge(partitioned_graph(pg), edge(pe))
end

function partition_edge(pg::AbstractPartitionedGraph, edge::AbstractEdge)
  return edgetype(partitioned_graph(pg))(
    partition_vertex(pg, src(edge)) => partition_vertex(pg, dst(edge))
  )
end

function is_boundary_edge(pg::AbstractPartitionedGraph, edge::AbstractEdge)
  p_edge = partition_edge(pg, edge)
  return src(p_edge) == dst(p_edge)
end

function partition_edges(pg::AbstractPartitionedGraph, p_edge)
  psrc_vs, pdst_vs = partition_vertices(pg, src(p_edge)),
  partition_vertices(pg, dst(p_edge))
  psrc_subgraph, pdst_subgraph, full_subgraph = subgraph(graph(pg), psrc_vs),
  subgraph(pg, pdst_vs),
  subgraph(pg, vcat(psrc_vs, pdst_vs))

  return setdiff(
    NamedGraphs.edges(full_subgraph),
    vcat(NamedGraphs.edges(psrc_subgraph), NamedGraphs.edges(pdst_subgraph)),
  )
end

function partition_edges(pg::AbstractPartitionedGraph, p_edge::AbstractPartitionEdge)
  return partition_edges(pg, edge(p_edge))
end

function add_edge!(pg::AbstractPartitionedGraph, edge::AbstractEdge)
  add_edge!(graph(pg), edge)
  pg_edge = partition_edge(pg, edge)
  if src(pg_edge) != dst(pg_edge)
    add_edge!(partitioned_graph(pg), pg_edge)
  end
end

function rem_edge!(pg::AbstractPartitionedGraph, edge::AbstractEdge)
  pg_edge = partition_edge(pg, edge)
  if has_edge(partitioned_graph(pg), pg_edge)
    g_edges = partition_edges(pg, pg_edge)
    if length(g_edges) == 1
      rem_edge!(partitioned_graph(pg), pg_edge)
    end
  end

  return rem_edge!(graph(pg), edge)
end

#Vertex addition and removal. I think it's important not to allow addition of a vertex without specification of PV
function add_vertex!(pg::AbstractPartitionedGraph, vertex, partition_vertex)
  add_vertex!(graph(pg), vertex)
  if partition_vertex ∉ vertices(partitioned_graph(pg))
    add_vertex!(partitioned_graph(pg), partition_vertex)
  end

  return add_to_vertex_map!(pg, vertex, partition_vertex)
end

function add_vertices!(
  pg::AbstractPartitionedGraph, vertices::Vector, partition_vertices::Vector
)
  @assert length(vertices) == length(partition_vertices)
  for (v, pv) in zip(vertices, partition_vertices)
    add_vertex!(pg, v, pv)
  end
end

function add_vertices!(pg::AbstractPartitionedGraph, vertices::Vector, partition_vertex)
  return add_vertices!(pg, vertices, fill(partition_vertex, length(vertices)))
end

function rem_vertex!(pg::AbstractPartitionedGraph, vertex)
  rem_vertex!(graph(pg), vertex)
  pv = partition_vertex(pg, vertex)
  if length(partition_vertices(pg, pv)) == 1
    rem_vertex!(partitioned_graph(pg), pv)
  end
  return rem_from_vertex_map!(pg, vertex)
end

function add_vertex!(pg::AbstractPartitionedGraph, vertex)
  return error("Need to specify a partition where the new vertex will go.")
end
