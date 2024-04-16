using Pkg: Pkg
active_project_dir = dirname(Base.active_project())
Pkg.activate(; temp=true, io=devnull)

Pkg.add("Graphs"; io=devnull)
using Graphs: nv
Pkg.develop("NamedGraphs"; io=devnull)
using NamedGraphs: named_grid
using NamedGraphs.PartitionedGraphs: PartitionedGraph, partitioned_graph

g = named_grid((4, 4))
npartitions = 4

Pkg.add("Metis"; io=devnull)
using Metis: Metis
pg_metis = PartitionedGraph(g; npartitions, backend="metis")
@show pg_metis isa PartitionedGraph
@show nv(partitioned_graph(pg_metis)) == npartitions

if !Sys.iswindows()
  # `KaHyPar` doesn't work on Windows.
  Pkg.add("KaHyPar"; io=devnull)
  using KaHyPar: KaHyPar
  pg_kahypar = PartitionedGraph(g; npartitions, backend="kahypar")
  @show pg_kahypar isa PartitionedGraph
  @show nv(partitioned_graph(pg_kahypar)) == npartitions
end

Pkg.activate(active_project_dir; io=devnull)
