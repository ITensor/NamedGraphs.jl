using Graphs: incidence_matrix
using .GraphsExtensions: GraphsExtensions
using SplitApplyCombine: groupfind
using KaHyPar: KaHyPar

set_partitioning_backend!(Backend"KaHyPar"())

# https://github.com/kahypar/KaHyPar.jl/issues/20
KaHyPar.HyperGraph(g::SimpleGraph) = incidence_matrix(g)

"""
partitioned_vertices(::Backend"KaHyPar", g::Graph, npartiations::Integer; objective="edge_cut", alg="kway", kwargs...)

- default_configuration => "cut_kKaHyPar_sea20.ini"
- :edge_cut => "cut_kKaHyPar_sea20.ini"
- :connectivity => "km1_kKaHyPar_sea20.ini"
- imbalance::Number=0.03
"""
function GraphsExtensions.partitioned_vertices(
  ::Backend"KaHyPar",
  g::SimpleGraph,
  npartitions::Integer;
  objective="edge_cut",
  alg="kway",
  configuration=nothing,
  kwargs...,
)
  if isnothing(configuration)
    configuration = joinpath(
      pkgdir(KaHyPar),
      "src",
      "config",
      kahypar_configurations[(objective=objective, alg=alg)],
    )
  end
  partitioned_verts = @suppress KaHyPar.partition(g, npartitions; configuration, kwargs...)
  return groupfind(partitioned_verts .+ 1)
end
