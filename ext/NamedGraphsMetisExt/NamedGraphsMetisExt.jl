module NamedGraphsMetisExt
using Graphs: AbstractSimpleGraph
using Metis: Metis
using NamedGraphs.GraphsExtensions: GraphsExtensions, @Backend_str
using SplitApplyCombine: groupfind

GraphsExtensions.set_partitioning_backend!(Backend"metis"())

# Metis configuration options
const METIS_ALGS = Dict(["kway" => :KWAY, "recursive" => :RECURSIVE])

"""
    partitioned_vertices(::Backend"metis", g::AbstractGraph, npartitions::Integer; alg="recursive")

Partition the graph `G` in `n` parts.
The partition algorithm is defined by the `alg` keyword:
 - :KWAY: multilevel k-way partitioning
 - :RECURSIVE: multilevel recursive bisection
"""
function GraphsExtensions.partitioned_vertices(
  ::Backend"metis", g::AbstractSimpleGraph, npartitions::Integer; alg="recursive", kwargs...
)
  metis_alg = METIS_ALGS[alg]
  partitioned_verts = Metis.partition(g, npartitions; alg=metis_alg, kwargs...)
  return groupfind(Int.(partitioned_verts))
end

end
