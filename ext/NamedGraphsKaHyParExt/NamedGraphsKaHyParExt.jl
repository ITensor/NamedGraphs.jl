module NamedGraphsKaHyParExt
using Graphs: AbstractSimpleGraph, incidence_matrix
using KaHyPar: KaHyPar
using NamedGraphs.GraphsExtensions: GraphsExtensions, @Backend_str
using SplitApplyCombine: groupfind
using Suppressor: @suppress

GraphsExtensions.set_partitioning_backend!(Backend"kahypar"())

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
const KAHYPAR_ALGS = Dict(
    [
        (objective = "edge_cut", alg = "kway") => "cut_kKaHyPar_sea20.ini",
        (objective = "edge_cut", alg = "recursive") => "cut_rKaHyPar_sea20.ini",
        (objective = "connectivity", alg = "kway") => "km1_kKaHyPar_sea20.ini",
        (objective = "connectivity", alg = "recursive") => "km1_rKaHyPar_sea20.ini",
    ]
)

"""
partitioned_vertices(::Backend"kahypar", g::Graph, npartiations::Integer; objective="edge_cut", alg="kway", kwargs...)

- default_configuration => "cut_kKaHyPar_sea20.ini"
- :edge_cut => "cut_kKaHyPar_sea20.ini"
- :connectivity => "km1_kKaHyPar_sea20.ini"
- imbalance::Number=0.03
"""
function GraphsExtensions.partitioned_vertices(
        ::Backend"kahypar",
        g::AbstractSimpleGraph,
        npartitions::Integer;
        objective = "edge_cut",
        alg = "kway",
        configuration = nothing,
        kwargs...,
    )
    if isnothing(configuration)
        configuration = joinpath(
            pkgdir(KaHyPar), "src", "config", KAHYPAR_ALGS[(; objective = objective, alg = alg)]
        )
    end
    # https://github.com/kahypar/KaHyPar.jl/issues/20
    partitioned_verts = @suppress KaHyPar.partition(
        incidence_matrix(g), npartitions; configuration, kwargs...
    )
    return groupfind(partitioned_verts .+ 1)
end
end
