set_partitioning_backend!(Backend"Metis"())

"""
    partitioned_vertices(::Backend"Metis", g::AbstractGraph, npartitions::Integer; alg="recursive")

Partition the graph `G` in `n` parts.
The partition algorithm is defined by the `alg` keyword:
 - :KWAY: multilevel k-way partitioning
 - :RECURSIVE: multilevel recursive bisection
"""
function partitioned_vertices(
  ::Backend"Metis", g::SimpleGraph, npartitions::Integer; alg="recursive", kwargs...
)
  metis_alg = metis_algs[alg]
  partitioned_verts = Metis.partition(g, npartitions; alg=metis_alg, kwargs...)
  return groupfind(Int.(partitioned_verts))
end
