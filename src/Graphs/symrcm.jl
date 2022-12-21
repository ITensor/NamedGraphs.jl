# SymRCM.symrcm overload
function symrcm(graph::AbstractGraph)
  return symrcm(adjacency_matrix(graph))
end

function symrcm_permute(graph::AbstractGraph)
  return permute_vertices(graph, symrcm(graph))
end
