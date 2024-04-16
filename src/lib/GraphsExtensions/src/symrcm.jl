# Symmetric sparse reverse Cuthill-McKee ordering
# https://en.wikipedia.org/wiki/Cuthill%E2%80%93McKee_algorithm
# https://github.com/PetrKryslUCSD/SymRCM.jl
# https://github.com/rleegates/CuthillMcKee.jl
function symrcm_perm end

function symrcm_permute(graph::AbstractGraph)
  return permute_vertices(graph, symrcm_perm(graph))
end
