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
function has_partition_vertex(pg::AbstractPartitionedGraph, vertex)
  return has_vertex(partitioned_graph(pg), vertex)
end
function has_partition_edge(pg::AbstractPartitionedGraph, edge)
  return has_edge(partitioned_graph(pg), edge)
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

function partition_edges(pg::AbstractPartitionedGraph, partition_edge::AbstractEdge)
  psrc_vs, pdst_vs = partition_vertices(pg, src(partition_edge)),
  partition_vertices(pg, dst(partition_edge))
  psrc_subgraph, pdst_subgraph, full_subgraph = subgraph(graph(pg), psrc_vs),
  subgraph(pg, pdst_vs),
  subgraph(pg, vcat(psrc_vs, pdst_vs))

  return setdiff(
    NamedGraphs.edges(full_subgraph),
    vcat(NamedGraphs.edges(psrc_subgraph), NamedGraphs.edges(pdst_subgraph)),
  )
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

function rem_partition_edge!(pg::AbstractPartitionedGraph, partition_edge::AbstractEdge)
  rem_edges!(pg, partition_edges(pg, partition_edge))
end

function rem_partition_edge(pg::AbstractPartitionedGraph, partition_edge::AbstractEdge)
  pg_new = deepcopy(pg)
  rem_partition_edge!(pg_new, partition_edge)
  return pg_new
end

function rem_partition_edges!(pg::AbstractPartitionedGraph, partition_edges::Vector{AbstractEdge})
  for p_edge in partition_edges
    rem_partition_edge!(pg, p_edge)
  end
end

function rem_partition_edges(pg::AbstractPartitionedGraph, partition_edges::Vector{AbstractEdge})
  pg_new = deepcopy(pg)
  rem_partition_edges!(pg_new, partition_edges)
  return pg_new
end

#Vertex addition and removal. I think it's important not to allow addition of a vertex without specification of PV
function add_vertex!(pg::AbstractPartitionedGraph, vertex, partition_vertex)
  add_vertex!(graph(pg), vertex)
  add_vertex!(partitioned_graph(pg), partition_vertex)

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

function rem_partition_vertex!(pg::AbstractPartitionedGraph, partition_vertex)
  rem_vertices!(pg, partition_vertices(pg, partition_vertex))
end

function rem_partition_vertex(pg::AbstractPartitionedGraph, partition_vertex)
  pg_new = deepcopy(pg)
  rem_partition_vertex!(pg_new, partition_vertex)
  return pg_new
end

function rem_partition_vertices!(pg::AbstractPartitionedGraph, partition_vertices::Vector)
  for pv in partition_vertices
    rem_partition_vertex!(pg, pv)
  end
end

function rem_partition_vertices(pg::AbstractPartitionedGraph, partition_vertices::Vector)
  pg_new = deepcopy(rem_partition_vertex)
  rem_partition_vertices!(pg_new, partition_vertices)
  return pg_new
end

function add_vertex!(pg::AbstractPartitionedGraph, vertex)
  return error("Need to specify a partition where the new vertex will go.")
end

function (pg1::AbstractPartitionedGraph == pg2::AbstractPartitionedGraph)

  if fieldnames(typeof(pg1)) != fieldnames(typeof(pg1))
    return false
  end

  for field in fieldnames(typeof(pg1))
      if getfield(pg1, field) != getfield(pg2, field)
          return false
      end
  end
  return true
end
