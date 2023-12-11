"""
Graph partitioning backend
"""
struct Backend{T} end

Backend(s::Symbol) = Backend{s}()
Backend(s::String) = Backend(Symbol(s))
Backend(backend::Backend) = backend

macro Backend_str(s)
  return :(Backend{$(Expr(:quote, Symbol(s)))})
end

"""
Current default graph partitioning backend
"""
const CURRENT_PARTITIONING_BACKEND = Ref{Union{Missing,Backend}}(missing)

"""
Get the graph partitioning backend
"""
current_partitioning_backend() = CURRENT_PARTITIONING_BACKEND[]

"""
Set the graph partitioning backend
"""
function set_partitioning_backend!(backend::Union{Missing,Backend,String})
  CURRENT_PARTITIONING_BACKEND[] = Backend(backend)
  return nothing
end

# KaHyPar configuration options
#
# configurations = readdir(joinpath(pkgdir(KaHyPar), "src", "config"))
#  "cut_kKaHyPar_sea20.ini"
#  "cut_rKaHyPar_sea20.ini"
#  "km1_kKaHyPar-E_sea20.ini"
#  "km1_kKaHyPar_eco_sea20.ini"
#  "km1_kKaHyPar_sea20.ini"
#  "km1_rKaHyPar_sea20.ini"
#
const kahypar_configurations = Dict([
  (objective="edge_cut", alg="kway") => "cut_kKaHyPar_sea20.ini",
  (objective="edge_cut", alg="recursive") => "cut_rKaHyPar_sea20.ini",
  (objective="connectivity", alg="kway") => "km1_kKaHyPar_sea20.ini",
  (objective="connectivity", alg="recursive") => "km1_rKaHyPar_sea20.ini",
])

# Metis configuration options
const metis_algs = Dict(["kway" => :KWAY, "recursive" => :RECURSIVE])

function _npartitions(
  g::AbstractGraph, npartitions::Integer, nvertices_per_partition::Nothing
)
  return npartitions
end

function _npartitions(
  g::AbstractGraph, npartitions::Nothing, nvertices_per_partition::Integer
)
  return nv(g) ÷ nvertices_per_partition
end

function _npartitions(g::AbstractGraph, npartitions::Int, nvertices_per_partition::Int)
  return error("Can't specify both `npartitions` and `nvertices_per_partition`")
end

function _npartitions(
  g::AbstractGraph, npartitions::Nothing, nvertices_per_partition::Nothing
)
  return error("Must specify either `npartitions` or `nvertices_per_partition`")
end

function partition(
  g::Graph;
  npartitions=nothing,
  nvertices_per_partition=nothing,
  backend=current_partitioning_backend(),
  kwargs...,
)
  #Metis cannot handle the edge case npartitions = 1, so we will fix it here for now
  #Is this now
  if (_npartitions(g, npartitions, nvertices_per_partition) == 1)
    return group(v -> 1, collect(vertices(g)))
  end

  return partition(
    Backend(backend), g, _npartitions(g, npartitions, nvertices_per_partition); kwargs...
  )
end

function partition(
  g::AbstractNamedGraph; npartitions=nothing, nvertices_per_partition=nothing, kwargs...
)
  vertex_partitions = partition(
    parent_graph(g); npartitions, nvertices_per_partition, kwargs...
  )
  #[inv(vertex_to_parent_vertex(g))[v] for v in partitions]
  # TODO: output the reverse of this dictionary (a Vector of Vector
  # of the vertices in each partition).
  # return Dictionary(vertices(g), partitions)
  return [
    parent_vertices_to_vertices(g, vertex_partition) for
    vertex_partition in vertex_partitions
  ]
end