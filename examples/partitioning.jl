using NamedGraphs
using KaHyPar
using Metis

g = named_grid((4, 4))
npartitions = 4

pg_kahypar = PartitionedGraph(g; npartitions, backend="KaHyPar")
pg_metis = PartitionedGraph(g; npartitions, backend="Metis")

@show nv(partitioned_graph(pg_kahypar)) == nv(partitioned_graph(pg_metis)) == npartitions

@show pg_kahypar isa PartitionedGraph
@show pg_metis isa PartitionedGraph
