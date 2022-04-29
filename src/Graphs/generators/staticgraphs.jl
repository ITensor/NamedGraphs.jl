function comb_tree(dims)
  @assert length(dims) == 2
  nx, ny = dims
  graph = grid_graph(dims)
  # TODO: rem_vertex!
  return graph
end
