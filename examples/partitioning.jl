using NamedGraphs
using Metis

g = named_grid((4, 4))
npartitions = 4

pg_metis = PartitionedGraph(g; npartitions, backend="Metis")

@show pg_metis isa PartitionedGraph

if !Sys.iswindows()
  using KaHyPar
  pg_kahypar = PartitionedGraph(g; npartitions, backend="KaHyPar")
  @show nv(partitioned_graph(pg_kahypar)) == nv(partitioned_graph(pg_metis)) == npartitions
  @show pg_kahypar isa PartitionedGraph
end
