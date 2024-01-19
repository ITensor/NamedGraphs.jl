struct PartitionedGraph{V,PV,G<:AbstractGraph{V},PG<:AbstractGraph{PV}} <:
       AbstractPartitionedGraph{V,PV}
  graph::G
  partitioned_graph::PG
  partitioned_vertices::Dictionary
  which_partition::Dictionary
end

##Constructors.
function PartitionedGraph(g::AbstractGraph, partitioned_vertices)
  pvs = keys(partitioned_vertices)
  pg = NamedGraph(pvs)
  which_partition = Dictionary()
  for v in vertices(g)
    v_pvs = Set(findall(pv -> v ∈ partitioned_vertices[pv], pvs))
    @assert length(v_pvs) == 1
    insert!(which_partition, v, first(v_pvs))
  end

  for e in edges(g)
    pv_src, pv_dst = which_partition[src(e)], which_partition[dst(e)]
    pe = NamedEdge(pv_src => pv_dst)
    if pv_src != pv_dst && !has_edge(pg, pe)
      add_edge!(pg, pe)
    end
  end

  return PartitionedGraph(g, pg, Dictionary(partitioned_vertices), which_partition)
end

function PartitionedGraph(partitioned_vertices)
  return PartitionedGraph(NamedGraph(keys(partitioned_vertices)), partitioned_vertices)
end

function PartitionedGraph(g::AbstractGraph; kwargs...)
  partitioned_vertices = partition_vertices(g; kwargs...)
  return PartitionedGraph(g, partitioned_vertices)
end

#Needed for interface
partitioned_graph(pg::PartitionedGraph) = getfield(pg, :partitioned_graph)
unpartitioned_graph(pg::PartitionedGraph) = getfield(pg, :graph)
partitioned_vertices(pg::PartitionedGraph) = getfield(pg, :partitioned_vertices)
which_partition(pg::PartitionedGraph) = getfield(pg, :which_partition)
parent_graph_type(PG::Type{<:PartitionedGraph}) = fieldtype(PG, :graph)
function vertices(pg::PartitionedGraph, partition_vert::PartitionVertex)
  return partitioned_vertices(pg)[parent(partition_vert)]
end
function vertices(pg::PartitionedGraph, partition_verts::Vector{<:PartitionVertex})
  return unique(reduce(vcat, [vertices(pg, pv) for pv in partition_verts]))
end
function which_partition(pg::PartitionedGraph, vertex)
  return PartitionVertex(which_partition(pg)[vertex])
end

function which_partitions(pg::PartitionedGraph, verts::Vector)
  return unique(which_partition(pg, v) for v in verts)
end

function which_partitionedge(pg::PartitionedGraph, edge::AbstractEdge)
  return PartitionEdge(
    parent(which_partition(pg, src(edge))) => parent(which_partition(pg, dst(edge)))
  )
end

#Lets filter out any self-edges from this. Although this makes it a bit consistent with which_partitionedge
function which_partitionedges(pg::PartitionedGraph, edges::Vector{<:AbstractEdge})
  return filter(e -> src(e) != dst(e), unique([which_partitionedge(pg, e) for e in edges]))
end

function partitionedges(pg::PartitionedGraph)
  return PartitionEdge.(edges(partitioned_graph(pg)))
end

function edges(pg::PartitionedGraph, partition_edge::PartitionEdge)
  psrc_vs = vertices(pg, PartitionVertex(src(partition_edge)))
  pdst_vs = vertices(pg, PartitionVertex(dst(partition_edge)))
  psrc_subgraph = subgraph(unpartitioned_graph(pg), psrc_vs)
  pdst_subgraph = subgraph(pg, pdst_vs)
  full_subgraph = subgraph(pg, vcat(psrc_vs, pdst_vs))

  return setdiff(edges(full_subgraph), vcat(edges(psrc_subgraph), edges(pdst_subgraph)))
end

function edges(pg::PartitionedGraph, partition_edges::Vector{<:PartitionEdge})
  return unique(reduce(vcat, [edges(pg, pe) for pe in partition_edges]))
end

function copy(pg::PartitionedGraph)
  return PartitionedGraph(
    copy(unpartitioned_graph(pg)),
    copy(partitioned_graph(pg)),
    copy_keys_values(partitioned_vertices(pg)),
    copy_keys_values(which_partition(pg)),
  )
end

function insert_to_vertex_map!(
  pg::PartitionedGraph, vertex, partition_vertex::PartitionVertex
)
  pv = parent(partition_vertex)
  if pv ∉ keys(partitioned_vertices(pg))
    insert!(partitioned_vertices(pg), pv, [vertex])
  else
    partitioned_vertices(pg)[pv] = unique(vcat(vertices(pg, partition_vertex), [vertex]))
  end

  insert!(which_partition(pg), vertex, pv)
  return pg
end

function delete_from_vertex_map!(pg::PartitionedGraph, vertex)
  pv = which_partition(pg, vertex)
  return delete_from_vertex_map!(pg, pv, vertex)
end

function delete_from_vertex_map!(
  pg::PartitionedGraph, partitioned_vertex::PartitionVertex, vertex
)
  vs = vertices(pg, partitioned_vertex)
  delete!(partitioned_vertices(pg), parent(partitioned_vertex))
  if length(vs) != 1
    insert!(partitioned_vertices(pg), parent(partitioned_vertex), setdiff(vs, [vertex]))
  end

  delete!(which_partition(pg), vertex)
  return partitioned_vertex
end

### PartitionedGraph Specific Functions
function induced_subgraph(pg::PartitionedGraph, vertices::Vector)
  sub_pg_graph, _ = induced_subgraph(unpartitioned_graph(pg), vertices)
  sub_partitioned_vertices = copy_keys_values(partitioned_vertices(pg))
  for pv in NamedGraphs.vertices(partitioned_graph(pg))
    vs = intersect(vertices, sub_partitioned_vertices[pv])
    if !isempty(vs)
      sub_partitioned_vertices[pv] = vs
    else
      delete!(sub_partitioned_vertices, pv)
    end
  end

  return PartitionedGraph(sub_pg_graph, sub_partitioned_vertices), nothing
end

function induced_subgraph(
  pg::PartitionedGraph, partition_verts::Vector{V}
) where {V<:PartitionVertex}
  return induced_subgraph(pg, vertices(pg, partition_verts))
end
