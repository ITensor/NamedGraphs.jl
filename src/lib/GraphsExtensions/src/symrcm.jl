# TODO: Move to `NamedGraphsSymRCMExt`.
using Graphs: AbstractGraph, adjacency_matrix
using SymRCM: SymRCM

# Symmetric sparse reverse Cuthill-McKee ordering
# https://en.wikipedia.org/wiki/Cuthill%E2%80%93McKee_algorithm
# https://github.com/PetrKryslUCSD/SymRCM.jl
# https://github.com/rleegates/CuthillMcKee.jl
function symrcm_perm(graph::AbstractGraph)
  return SymRCM.symrcm(adjacency_matrix(graph))
end

function symrcm_permute(graph::AbstractGraph)
  return permute_vertices(graph, symrcm_perm(graph))
end
