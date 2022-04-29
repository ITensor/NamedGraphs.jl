function comb_tree(dims)
  @assert length(dims) == 2
  nx, ny = dims
  graph = grid(dims)
  # TODO: rem_vertex!
  for I in CartesianIndices((nx, ny))
    jx, jy = Tuple(I)
    j = LinearIndices((nx, ny))[I]
    if jy > 1 && jx < nx
      println("Remove $j => $(j + 1)")
      rem_edge!(graph, Edge(j, j + 1))
    end
  end
  return graph
end
