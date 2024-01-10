abstract type AbstractPartitionedGraph{V,PV} <: AbstractNamedGraph{V} end

#Needed for interface
partitioned_graph(pg::AbstractPartitionedGraph) = not_implemented()
unpartitioned_graph(pg::AbstractPartitionedGraph) = not_implemented()
which_partition(pg::AbstractPartitionedGraph, vertex) = not_implemented()
partitioned_vertices(pg::AbstractPartitionedGraph) = not_implemented()
copy(pg::AbstractPartitionedGraph) = not_implemented()
delete_from_vertex_map!(pg::AbstractPartitionedGraph, vertex) = not_implemented()
insert_to_vertex_map!(pg::AbstractPartitionedGraph, vertex) = not_implemented()
partition_edge(pg::AbstractPartitionedGraph, edge) = not_implemented()
function edges(pg::AbstractPartitionedGraph, partition_edge::AbstractPartitionEdge)
  return not_implemented()
end
vertices(pg::AbstractPartitionedGraph, pv::AbstractPartitionVertex) = not_implemented()
function vertices(
  pg::AbstractPartitionedGraph, partition_verts::Vector{V}
) where {V<:AbstractPartitionVertex}
  return not_implemented()
end
parent_graph_type(PG::Type{<:AbstractPartitionedGraph}) = not_implemented()
directed_graph_type(PG::Type{<:AbstractPartitionedGraph}) = not_implemented()
undirected_graph_type(PG::Type{<:AbstractPartitionedGraph}) = not_implemented()

#Functions for the abstract type
vertices(pg::AbstractPartitionedGraph) = vertices(unpartitioned_graph(pg))
parent_graph(pg::AbstractPartitionedGraph) = parent_graph(unpartitioned_graph(pg))
function vertex_to_parent_vertex(pg::AbstractPartitionedGraph, vertex)
  return vertex_to_parent_vertex(unpartitioned_graph(pg), vertex)
end
edgetype(pg::AbstractPartitionedGraph) = edgetype(unpartitioned_graph(pg))
parent_graph_type(pg::AbstractPartitionedGraph) = parent_graph_type(unpartitioned_graph(pg))
nv(pg::AbstractPartitionedGraph, pv::AbstractPartitionVertex) = length(vertices(pg, pv))
function has_vertex(pg::AbstractPartitionedGraph, partition_vertex::AbstractPartitionVertex)
  return has_vertex(partitioned_graph(pg), parent(partition_vertex))
end

function has_edge(pg::AbstractPartitionedGraph, edge::AbstractPartitionEdge)
  return has_edge(partitioned_graph(pg), parent(partition_edge))
end

function is_boundary_edge(pg::AbstractPartitionedGraph, edge::AbstractEdge)
  p_edge = partition_edge(pg, edge)
  return src(p_edge) == dst(p_edge)
end

function add_edge!(pg::AbstractPartitionedGraph, edge::AbstractEdge)
  add_edge!(unpartitioned_graph(pg), edge)
  pg_edge = parent(partition_edge(pg, edge))
  if src(pg_edge) != dst(pg_edge)
    add_edge!(partitioned_graph(pg), pg_edge)
  end

  return pg
end

function rem_edge!(pg::AbstractPartitionedGraph, edge::AbstractEdge)
  pg_edge = partition_edge(pg, edge)
  if has_edge(partitioned_graph(pg), pg_edge)
    g_edges = edges(pg, pg_edge)
    if length(g_edges) == 1
      rem_edge!(partitioned_graph(pg), pg_edge)
    end
  end
  return rem_edge!(unpartitioned_graph(pg), edge)
end

function rem_edge!(pg::AbstractPartitionedGraph, partition_edge::AbstractPartitionEdge)
  return rem_edges!(pg, edges(pg, parent(partition_edge)))
end

function rem_edge(pg::AbstractPartitionedGraph, partition_edge::AbstractPartitionEdge)
  pg_new = copy(pg)
  rem_edge!(pg_new, partition_edge)
  return pg_new
end

function rem_edges!(
  pg::AbstractPartitionedGraph, partition_edges::Vector{<:AbstractPartitionEdge}
)
  for pe in partition_edges
    rem_edge!(pg, pe)
  end
  return pg
end

function rem_edges(
  pg::AbstractPartitionedGraph, partition_edges::Vector{<:AbstractPartitionEdge}
)
  pg_new = copy(pg)
  rem_edges!(pg_new, partition_edges)
  return pg_new
end

#Vertex addition and removal. I think it's important not to allow addition of a vertex without specification of PV
function add_vertex!(
  pg::AbstractPartitionedGraph, vertex, partition_vertex::AbstractPartitionVertex
)
  add_vertex!(unpartitioned_graph(pg), vertex)
  add_vertex!(partitioned_graph(pg), parent(partition_vertex))
  insert_to_vertex_map!(pg, vertex, partition_vertex)
  return pg
end

function add_vertices!(
  pg::AbstractPartitionedGraph,
  vertices::Vector,
  partition_vertices::Vector{<:AbstractPartitionVertex},
)
  @assert length(vertices) == length(partition_vertices)
  for (v, pv) in zip(vertices, partition_vertices)
    add_vertex!(pg, v, pv)
  end

  return pg
end

function add_vertices!(
  pg::AbstractPartitionedGraph, vertices::Vector, partition_vertex::AbstractPartitionVertex
)
  add_vertices!(pg, vertices, fill(partition_vertex, length(vertices)))
  return pg
end

function rem_vertex!(pg::AbstractPartitionedGraph, vertex)
  pv = which_partition(pg, vertex)
  delete_from_vertex_map!(pg, pv, vertex)
  rem_vertex!(unpartitioned_graph(pg), vertex)
  if !haskey(partitioned_vertices(pg), parent(pv))
    rem_vertex!(partitioned_graph(pg), parent(pv))
  end
  return pg
end

function rem_vertex!(
  pg::AbstractPartitionedGraph, partition_vertex::AbstractPartitionVertex
)
  rem_vertices!(pg, vertices(pg, partition_vertex))
  return pg
end

function rem_vertex(pg::AbstractPartitionedGraph, partition_vertex::AbstractPartitionVertex)
  pg_new = copy(pg)
  rem_vertex!(pg_new, partition_vertex)
  return pg_new
end

function add_vertex!(pg::AbstractPartitionedGraph, vertex)
  return error("Need to specify a partition where the new vertex will go.")
end

function (pg1::AbstractPartitionedGraph == pg2::AbstractPartitionedGraph)
  if unpartitioned_graph(pg1) != unpartitioned_graph(pg2) ||
    partitioned_graph(pg1) != partitioned_graph(pg2)
    return false
  end
  for v in vertices(pg1)
    if which_partition(pg1, v) != which_partition(pg2, v)
      return false
    end
  end
  return true
end

function subgraph(pg::AbstractPartitionedGraph, partition_vertex::AbstractPartitionVertex)
  return first(induced_subgraph(unpartitioned_graph(pg), vertices(pg, [partition_vertex])))
end

function induced_subgraph(
  pg::AbstractPartitionedGraph, partition_vertex::AbstractPartitionVertex
)
  return subgraph(pg, partition_vertex), nothing
end
