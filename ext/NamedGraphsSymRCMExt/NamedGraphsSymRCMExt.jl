module NamedGraphsSymRCMExt
using Graphs: AbstractGraph, adjacency_matrix
using NamedGraphs.GraphsExtensions: GraphsExtensions
using SymRCM: SymRCM

function GraphsExtensions.symrcm_perm(graph::AbstractGraph)
    return SymRCM.symrcm(adjacency_matrix(graph))
end
end
