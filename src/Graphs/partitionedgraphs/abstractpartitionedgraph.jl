abstract type AbstractPartitionedGraph{V,PV} <: AbstractNamedGraph{V} end

#Needed for interface
partitioned_graph(pg::AbstractPartitionedGraph) = not_implemented()
unpartitioned_graph(pg::AbstractPartitionedGraph) = not_implemented()
partitionvertex(pg::AbstractPartitionedGraph, vertex) = not_implemented()
partitionvertices(pg::AbstractPartitionedGraph, verts::Vector) = not_implemented()
partitionvertices(pg::AbstractPartitionedGraph) = not_implemented()
copy(pg::AbstractPartitionedGraph) = not_implemented()
delete_from_vertex_map!(pg::AbstractPartitionedGraph, vertex) = not_implemented()
insert_to_vertex_map!(pg::AbstractPartitionedGraph, vertex) = not_implemented()
partitionedge(pg::AbstractPartitionedGraph, edge) = not_implemented()
function partitionedges(pg::AbstractPartitionedGraph, edges::Vector{<:AbstractEdge})
  return not_implemented()
end
partitionedges(pg::AbstractPartitionedGraph) = not_implemented()
function edges(pg::AbstractPartitionedGraph, partitionedge::AbstractPartitionEdge)
  return not_implemented()
end
vertices(pg::AbstractPartitionedGraph, pv::AbstractPartitionVertex) = not_implemented()
function vertices(
  pg::AbstractPartitionedGraph, partitionverts::Vector{V}
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
function has_vertex(pg::AbstractPartitionedGraph, partitionvertex::AbstractPartitionVertex)
  return has_vertex(partitioned_graph(pg), parent(partitionvertex))
end

function has_edge(pg::AbstractPartitionedGraph, partitionedge::AbstractPartitionEdge)
  return has_edge(partitioned_graph(pg), parent(partitionedge))
end

function is_boundary_edge(pg::AbstractPartitionedGraph, edge::AbstractEdge)
  p_edge = partitionedge(pg, edge)
  return src(p_edge) == dst(p_edge)
end

function add_edge!(pg::AbstractPartitionedGraph, edge::AbstractEdge)
  add_edge!(unpartitioned_graph(pg), edge)
  pg_edge = parent(partitionedge(pg, edge))
  if src(pg_edge) != dst(pg_edge)
    add_edge!(partitioned_graph(pg), pg_edge)
  end

  return pg
end

function rem_edge!(pg::AbstractPartitionedGraph, edge::AbstractEdge)
  pg_edge = partitionedge(pg, edge)
  if has_edge(partitioned_graph(pg), pg_edge)
    g_edges = edges(pg, pg_edge)
    if length(g_edges) == 1
      rem_edge!(partitioned_graph(pg), pg_edge)
    end
  end
  return rem_edge!(unpartitioned_graph(pg), edge)
end

function rem_edge!(pg::AbstractPartitionedGraph, partitionedge::AbstractPartitionEdge)
  return rem_edges!(pg, edges(pg, parent(partitionedge)))
end

function rem_edge(pg::AbstractPartitionedGraph, partitionedge::AbstractPartitionEdge)
  pg_new = copy(pg)
  rem_edge!(pg_new, partitionedge)
  return pg_new
end

function rem_edges!(
  pg::AbstractPartitionedGraph, partitionedges::Vector{<:AbstractPartitionEdge}
)
  for pe in partitionedges
    rem_edge!(pg, pe)
  end
  return pg
end

function rem_edges(
  pg::AbstractPartitionedGraph, partitionedges::Vector{<:AbstractPartitionEdge}
)
  pg_new = copy(pg)
  rem_edges!(pg_new, partitionedges)
  return pg_new
end

#Vertex addition and removal. I think it's important not to allow addition of a vertex without specification of PV
function add_vertex!(
  pg::AbstractPartitionedGraph, vertex, partitionvertex::AbstractPartitionVertex
)
  add_vertex!(unpartitioned_graph(pg), vertex)
  add_vertex!(partitioned_graph(pg), parent(partitionvertex))
  insert_to_vertex_map!(pg, vertex, partitionvertex)
  return pg
end

function add_vertices!(
  pg::AbstractPartitionedGraph,
  vertices::Vector,
  partitionvertices::Vector{<:AbstractPartitionVertex},
)
  @assert length(vertices) == length(partitionvertices)
  for (v, pv) in zip(vertices, partitionvertices)
    add_vertex!(pg, v, pv)
  end

  return pg
end

function add_vertices!(
  pg::AbstractPartitionedGraph, vertices::Vector, partitionvertex::AbstractPartitionVertex
)
  add_vertices!(pg, vertices, fill(partitionvertex, length(vertices)))
  return pg
end

function rem_vertex!(pg::AbstractPartitionedGraph, vertex)
  pv = partitionvertex(pg, vertex)
  delete_from_vertex_map!(pg, pv, vertex)
  rem_vertex!(unpartitioned_graph(pg), vertex)
  if !haskey(partitioned_vertices(pg), parent(pv))
    rem_vertex!(partitioned_graph(pg), parent(pv))
  end
  return pg
end

function rem_vertex!(pg::AbstractPartitionedGraph, partitionvertex::AbstractPartitionVertex)
  rem_vertices!(pg, vertices(pg, partitionvertex))
  return pg
end

function rem_vertex(pg::AbstractPartitionedGraph, partitionvertex::AbstractPartitionVertex)
  pg_new = copy(pg)
  rem_vertex!(pg_new, partitionvertex)
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
    if partitionvertex(pg1, v) != partitionvertex(pg2, v)
      return false
    end
  end
  return true
end

function subgraph(pg::AbstractPartitionedGraph, partitionvertex::AbstractPartitionVertex)
  return first(induced_subgraph(unpartitioned_graph(pg), vertices(pg, [partitionvertex])))
end

function induced_subgraph(
  pg::AbstractPartitionedGraph, partitionvertex::AbstractPartitionVertex
)
  return subgraph(pg, partitionvertex), nothing
end
