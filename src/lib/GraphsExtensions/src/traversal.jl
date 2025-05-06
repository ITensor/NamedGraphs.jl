
#Given a graph, traverse it from start vertex to end vertex, covering each edge exactly once.
#Complexity is O(length(edges(g)))
function eulerian_path(g::AbstractGraph, start_vertex, end_vertex)
  #Conditions on g for the required path to exist
  if start_vertex != end_vertex
    @assert isodd(degree(g, start_vertex) % 2)
    @assert isodd(degree(g, end_vertex) % 2)
    @assert all(
      x -> iseven(x), degrees(g, setdiff(vertices(g), [start_vertex, end_vertex]))
    )
  else
    @assert all(x -> iseven(x), degrees(g, vertices(g)))
  end

  path = []
  stack = []
  current_vertex = end_vertex
  g_modified = copy(g)
  while !isempty(stack) || !iszero(degree(g_modified, current_vertex))
    if iszero(degree(g_modified, current_vertex))
      append!(path, current_vertex)
      last_vertex = pop!(stack)
      current_vertex = last_vertex
    else
      append!(stack, current_vertex)
      vn = first(neighbors(g_modified, current_vertex))
      rem_edge!(g_modified, edgetype(g_modified)(current_vertex, vn))
      current_vertex = vn
    end
  end

  append!(path, current_vertex)

  return edgetype(g_modified)[
    edgetype(g_modified)(path[i], path[i + 1]) for i in 1:(length(path) - 1)
  ]
end

function eulerian_cycle(g::AbstractGraph, start_vertex)
  return eulerian_path(g, start_vertex, start_vertex)
end
