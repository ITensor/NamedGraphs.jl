using Dictionaries: Dictionary
using Graphs:
  AbstractEdge, AbstractGraph, add_edge!, edges, has_edge, induced_subgraph, vertices
using .GraphsExtensions:
  GraphsExtensions, boundary_edges, is_self_loop, partitioned_vertices
using ..NamedGraphs: NamedEdge, NamedGraph

# TODO: Parametrize `partitioned_vertices` and `which_partition`,
# see https://github.com/mtfishman/NamedGraphs.jl/issues/63.
struct PartitionedGraph{V,PV,G<:AbstractGraph{V},PG<:AbstractGraph{PV}} <:
       AbstractPartitionedGraph{V,PV}
  graph::G
  partitions_graph::PG
  partitioned_vertices::Dictionary
  which_partition::Dictionary
end

##Constructors.
function PartitionedGraph(g::AbstractGraph, partitioned_vertices)
  pvs = keys(partitioned_vertices)
  pg = NamedGraph(pvs)
  # TODO: Make this type more specific.
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
partitions_graph(pg::PartitionedGraph) = getfield(pg, :partitions_graph)
unpartitioned_graph(pg::PartitionedGraph) = getfield(pg, :graph)
function unpartitioned_graph_type(graph_type::Type{<:PartitionedGraph})
  return fieldtype(graph_type, :graph)
end
function GraphsExtensions.partitioned_vertices(pg::PartitionedGraph)
  return getfield(pg, :partitioned_vertices)
end
which_partition(pg::PartitionedGraph) = getfield(pg, :which_partition)
function Graphs.vertices(pg::PartitionedGraph, partitionvert::PartitionVertex)
  return partitioned_vertices(pg)[parent(partitionvert)]
end
function Graphs.vertices(pg::PartitionedGraph, partitionverts::Vector{<:PartitionVertex})
  return unique(reduce(vcat, Iterators.map(pv -> vertices(pg, pv), partitionverts)))
end
function partitionvertex(pg::PartitionedGraph, vertex)
  return PartitionVertex(which_partition(pg)[vertex])
end

function partitionvertices(pg::PartitionedGraph, verts)
  return unique(partitionvertex(pg, v) for v in verts)
end

function partitionvertices(pg::PartitionedGraph)
  return PartitionVertex.(vertices(partitions_graph(pg)))
end

function partitionedge(pg::PartitionedGraph, edge::AbstractEdge)
  return PartitionEdge(
    parent(partitionvertex(pg, src(edge))) => parent(partitionvertex(pg, dst(edge)))
  )
end

partitionedge(pg::PartitionedGraph, p::Pair) = partitionedge(pg, edgetype(pg)(p))

function partitionedges(pg::PartitionedGraph, edges::Vector)
  return filter(!is_self_loop, unique([partitionedge(pg, e) for e in edges]))
end

function partitionedges(pg::PartitionedGraph)
  return PartitionEdge.(edges(partitions_graph(pg)))
end

function Graphs.edges(pg::PartitionedGraph, partitionedge::PartitionEdge)
  psrc_vs = vertices(pg, src(partitionedge))
  pdst_vs = vertices(pg, dst(partitionedge))
  psrc_subgraph, _ = induced_subgraph(unpartitioned_graph(pg), psrc_vs)
  pdst_subgraph, _ = induced_subgraph(pg, pdst_vs)
  full_subgraph, _ = induced_subgraph(pg, vcat(psrc_vs, pdst_vs))

  return setdiff(edges(full_subgraph), vcat(edges(psrc_subgraph), edges(pdst_subgraph)))
end

function Graphs.edges(pg::PartitionedGraph, partitionedges::Vector{<:PartitionEdge})
  return unique(reduce(vcat, [edges(pg, pe) for pe in partitionedges]))
end

function boundary_partitionedges(pg::PartitionedGraph, partitionvertices; kwargs...)
  return PartitionEdge.(
    boundary_edges(partitions_graph(pg), parent.(partitionvertices); kwargs...)
  )
end

function boundary_partitionedges(
  pg::PartitionedGraph, partitionvertex::PartitionVertex; kwargs...
)
  return boundary_partitionedges(pg, [partitionvertex]; kwargs...)
end

function Base.copy(pg::PartitionedGraph)
  return PartitionedGraph(
    copy(unpartitioned_graph(pg)),
    copy(partitions_graph(pg)),
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
function partitionedgraph_induced_subgraph(pg::PartitionedGraph, vertices::Vector)
  sub_pg_graph, _ = induced_subgraph(unpartitioned_graph(pg), vertices)
  sub_partitioned_vertices = copy(partitioned_vertices(pg))
  for pv in NamedGraphs.vertices(partitions_graph(pg))
    vs = intersect(vertices, sub_partitioned_vertices[pv])
    if !isempty(vs)
      sub_partitioned_vertices[pv] = vs
    else
      delete!(sub_partitioned_vertices, pv)
    end
  end

  return PartitionedGraph(sub_pg_graph, sub_partitioned_vertices), nothing
end

function partitionedgraph_induced_subgraph(
  pg::PartitionedGraph, partitionverts::Vector{<:PartitionVertex}
)
  return induced_subgraph(pg, vertices(pg, partitionverts))
end

function Graphs.induced_subgraph(pg::PartitionedGraph, vertices)
  return partitionedgraph_induced_subgraph(pg, vertices)
end

# Fixes ambiguity error with `Graphs.jl`.
function Graphs.induced_subgraph(pg::PartitionedGraph, vertices::Vector{<:Integer})
  return partitionedgraph_induced_subgraph(pg, vertices)
end
