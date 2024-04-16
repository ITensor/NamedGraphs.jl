module GraphGenerators
using Dictionaries: Dictionary
using Graphs: SimpleGraph, add_edge!

function comb_tree(dims::Tuple)
  @assert length(dims) == 2
  nx, ny = dims
  return comb_tree(fill(ny, nx))
end

function comb_tree(tooth_lengths::Vector{<:Integer})
  @assert all(>(0), tooth_lengths)
  nv = sum(tooth_lengths)
  nx = length(tooth_lengths)
  ny = maximum(tooth_lengths)
  vertex_coordinates = filter(Tuple.(CartesianIndices((nx, ny)))) do (jx, jy)
    jy <= tooth_lengths[jx]
  end
  coordinate_to_vertex = Dictionary(vertex_coordinates, 1:nv)
  graph = SimpleGraph(nv)
  for (jx, jy) in vertex_coordinates
    if jy == 1 && jx < nx
      add_edge!(graph, coordinate_to_vertex[(jx, jy)], coordinate_to_vertex[(jx + 1, jy)])
    end
    if jy < tooth_lengths[jx]
      add_edge!(graph, coordinate_to_vertex[(jx, jy)], coordinate_to_vertex[(jx, jy + 1)])
    end
  end
  return graph
end
end
