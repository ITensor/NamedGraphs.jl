using Graphs
using KaHyPar
using Metis

g = named_grid((4, 4))
npartitions = 4

pg_kahypar = PartitionedGraph(g; npartitions, backend="KaHyPar")
pg_metis = PartitionedGraph(g; npartitions, backend="KaHyPar")

@show length(vertices(pg_kahypar.partitioned_graph)) ==
  length(vertices(pg_metis.partitioned_graph))
