module NamedGraphsSymRCMExt
using Graphs: AbstractGraph, adjacency_matrix
using NamedGraphs: NamedGraphs
using SymRCM: SymRCM

function NamedGraphs.symrcm_perm(graph::AbstractGraph)
    return SymRCM.symrcm(adjacency_matrix(graph))
end
end
