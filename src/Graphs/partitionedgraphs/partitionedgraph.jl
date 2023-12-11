struct PartitionedGraph{V,PV,G<:AbstractNamedGraph{V},PG<:AbstractNamedGraph{PV}} <:
       AbstractPartitionedGraph{V,PV}
  graph::G
  partitioned_graph::PG
  partition_vertices::Dictionary{PV,Vector{V}}
  partition_vertex::Dictionary{V,PV}
end

##Constructors.
function PartitionedGraph{V,PV,G,PG}(
  g::AbstractNamedGraph{V}, partition_vertices::Dictionary{PV,Vector{V}}
) where {V,PV,G<:AbstractNamedGraph{V},PG<:AbstractNamedGraph{PV}}
  pvs = keys(partition_vertices)
  pg = NamedGraph(pvs)
  partition_vertex = Dictionary{V,PV}()
  for v in vertices(g)
    v_pvs = Set(findall(pv -> v ∈ partition_vertices[pv], pvs))
    @assert length(v_pvs) == 1
    insert!(partition_vertex, v, first(v_pvs))
  end

  for e in edges(g)
    pv_src, pv_dst = partition_vertex[src(e)], partition_vertex[dst(e)]
    pe = NamedEdge(pv_src => pv_dst)
    if pv_src != pv_dst && !has_edge(pg, pe)
      add_edge!(pg, pe)
    end
  end

  return PartitionedGraph(g, pg, partition_vertices, partition_vertex)
end

function PartitionedGraph(
  g::AbstractNamedGraph{V}, partition_vertices::Dictionary{PV,Vector{V}}
) where {V,PV}
  return PartitionedGraph{V,PV,NamedGraph{V},NamedGraph{PV}}(g, partition_vertices)
end

function PartitionedGraph{V,Int64,G,NamedGraph{Int64}}(
  g::AbstractNamedGraph{V}, partition_vertices::Vector{Vector{V}}
) where {V,G<:NamedGraph{V}}
  partition_vertices_dict = Dictionary{Int64,Vector{V}}(
    [i for i in 1:length(partition_vertices)], partition_vertices
  )
  return PartitionedGraph{V,Int64,NamedGraph{V},NamedGraph{Int64}}(
    g, partition_vertices_dict
  )
end

function PartitionedGraph(
  g::AbstractNamedGraph{V}, partition_vertices::Vector{Vector{V}}
) where {V}
  return PartitionedGraph{V,Int64,NamedGraph{V},NamedGraph{Int64}}(g, partition_vertices)
end

function PartitionedGraph{V,V,G,G}(vertices::Vector{V}) where {V,G<:NamedGraph{V}}
  return PartitionedGraph(NamedGraph{V}(vertices), [[v] for v in vertices])
end

function PartitionedGraph(vertices::Vector{V}) where {V}
  return PartitionedGraph{V,V,NamedGraph{V},NamedGraph{V}}(vertices)
end

function PartitionedGraph(g::AbstractNamedGraph{V}; npartitions=nothing,
  nvertices_per_partition=nothing,
  backend=current_partitioning_backend(),
  kwargs...) where{V}
  partition_vertices = partition(g; npartitions, nvertices_per_partition, backend, kwargs...)
  return PartitionedGraph(g, partition_vertices)
end

#Needed for interface
partitioned_graph(pg::PartitionedGraph) = getfield(pg, :partitioned_graph)
graph(pg::PartitionedGraph) = getfield(pg, :graph)
partition_vertices(pg::PartitionedGraph) = getfield(pg, :partition_vertices)
partition_vertex(pg::PartitionedGraph) = getfield(pg, :partition_vertex)
function partition_vertices(pg::PartitionedGraph, partition_vertex)
  return partition_vertices(pg)[partition_vertex]
end
partition_vertex(pg::PartitionedGraph, vertex) = partition_vertex(pg)[vertex]
function copy(pg::PartitionedGraph)
  return PartitionedGraph(
    copy(graph(pg)),
    copy(partitioned_graph(pg)),
    copy(partition_vertices(pg)),
    copy(partition_vertex(pg)),
  )
end

function add_to_vertex_map!(pg::PartitionedGraph, vertex, partition_vertex)
  if partition_vertex ∉ keys(partition_vertices(pg))
    insert!(partition_vertices(pg), partition_vertex, [vertex])
  else
    pg.partition_vertices[partition_vertex] = unique(
      vcat(partition_vertices(pg, partition_vertex), [vertex])
    )
  end

  return insert!(NamedGraphs.partition_vertex(pg), vertex, partition_vertex)
end

function rem_from_vertex_map!(pg::PartitionedGraph, vertex)
  pv = partition_vertex(pg, vertex)
  vs = partition_vertices(pg, pv)
  delete!(partition_vertices(pg), pv)
  if length(vs) != 1
    insert!(partition_vertices(pg), pv, setdiff(vs, [vertex]))
  end
  return delete!(pg.partition_vertex, vertex)
end

### PartitionedGraph Specific Functions
function induced_subgraph(pg::PartitionedGraph, vertices::Vector)
  sub_pg_graph, _ = induced_subgraph(graph(pg), vertices)
  sub_partition_vertices = deepcopy(partition_vertices(pg))
  for pv in NamedGraphs.vertices(partitioned_graph(pg))
    vs = intersect(vertices, sub_partition_vertices[pv])
    if !isempty(vs)
      sub_partition_vertices[pv] = vs
    else
      delete!(sub_partition_vertices, pv)
    end
  end

  return PartitionedGraph(sub_pg_graph, sub_partition_vertices), nothing
end
