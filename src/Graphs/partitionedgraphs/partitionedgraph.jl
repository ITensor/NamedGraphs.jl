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
  partitioned_verts = partitioned_vertices(g; kwargs...)
  return PartitionedGraph(g, partitioned_verts)
end

#Needed for interface
partitioned_graph(pg::PartitionedGraph) = getfield(pg, :partitioned_graph)
unpartitioned_graph(pg::PartitionedGraph) = getfield(pg, :graph)
partitioned_vertices(pg::PartitionedGraph) = getfield(pg, :partitioned_vertices)
which_partition(pg::PartitionedGraph) = getfield(pg, :which_partition)
parent_graph_type(PG::Type{<:PartitionedGraph}) = fieldtype(PG, :graph)
function vertices(pg::PartitionedGraph, partitionvert::PartitionVertex)
  return partitioned_vertices(pg)[parent(partitionvert)]
end
function vertices(pg::PartitionedGraph, partitionverts::Vector{<:PartitionVertex})
  return unique(reduce(vcat, [vertices(pg, pv) for pv in partitionverts]))
end
function partitionvertex(pg::PartitionedGraph, vertex)
  return PartitionVertex(which_partition(pg)[vertex])
end

function partitionvertices(pg::PartitionedGraph, verts::Vector)
  return unique(partitionvertex(pg, v) for v in verts)
end

function partitionvertices(pg::PartitionedGraph)
  return PartitionVertex.(vertices(partitioned_graph(pg)))
end

function partitionedge(pg::PartitionedGraph, edge::AbstractEdge)
  return PartitionEdge(
    parent(partitionvertex(pg, src(edge))) => parent(partitionvertex(pg, dst(edge)))
  )
end

partitionedge(pg::PartitionedGraph, p::Pair) = partitionedge(pg, edgetype(pg)(p))

is_self_loop(e::AbstractEdge) = src(e) == dst(e)
is_self_loop(e::Pair) = first(e) == last(e)

function partitionedges(pg::PartitionedGraph, edges::Vector)
  return filter(!is_self_loop, unique([partitionedge(pg, e) for e in edges]))
end

function partitionedges(pg::PartitionedGraph)
  return PartitionEdge.(edges(partitioned_graph(pg)))
end

function edges(pg::PartitionedGraph, partitionedge::PartitionEdge)
  psrc_vs = vertices(pg, PartitionVertex(src(partitionedge)))
  pdst_vs = vertices(pg, PartitionVertex(dst(partitionedge)))
  psrc_subgraph = subgraph(unpartitioned_graph(pg), psrc_vs)
  pdst_subgraph = subgraph(pg, pdst_vs)
  full_subgraph = subgraph(pg, vcat(psrc_vs, pdst_vs))

  return setdiff(edges(full_subgraph), vcat(edges(psrc_subgraph), edges(pdst_subgraph)))
end

function edges(pg::PartitionedGraph, partitionedges::Vector{<:PartitionEdge})
  return unique(reduce(vcat, [edges(pg, pe) for pe in partitionedges]))
end

function copy(pg::PartitionedGraph)
  return PartitionedGraph(
    copy(unpartitioned_graph(pg)),
    copy(partitioned_graph(pg)),
    copy(partitioned_vertices(pg)),
    copy(which_partition(pg)),
  )
end

function insert_to_vertex_map!(
  pg::PartitionedGraph, vertex, partitionvertex::PartitionVertex
)
  pv = parent(partitionvertex)
  if pv ∉ keys(partitioned_vertices(pg))
    insert!(partitioned_vertices(pg), pv, [vertex])
  else
    partitioned_vertices(pg)[pv] = unique(vcat(vertices(pg, partitionvertex), [vertex]))
  end

  insert!(which_partition(pg), vertex, pv)
  return pg
end

function delete_from_vertex_map!(pg::PartitionedGraph, vertex)
  pv = partitionvertex(pg, vertex)
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
  sub_partitioned_vertices = copy(partitioned_vertices(pg))
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
  pg::PartitionedGraph, partitionverts::Vector{V}
) where {V<:PartitionVertex}
  return induced_subgraph(pg, vertices(pg, partitionverts))
end
