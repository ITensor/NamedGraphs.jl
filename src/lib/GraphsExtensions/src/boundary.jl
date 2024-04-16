using Graphs: AbstractGraph, dst, src, vertices

# https://en.wikipedia.org/wiki/Boundary_(graph_theory)
function boundary_edges(graph::AbstractGraph, subgraph_vertices; dir=:out)
  E = edgetype(graph)
  subgraph_vertices_set = Set(subgraph_vertices)
  subgraph_complement = setdiff(Set(vertices(graph)), subgraph_vertices_set)
  boundary_es = Vector{E}()
  for subgraph_vertex in subgraph_vertices_set
    for e in incident_edges(graph, subgraph_vertex; dir)
      if src(e) ∈ subgraph_complement || dst(e) ∈ subgraph_complement
        push!(boundary_es, e)
      end
    end
  end
  return boundary_es
end

# https://en.wikipedia.org/wiki/Boundary_(graph_theory)
# See implementation of `Graphs.neighborhood_dists` as a reference.
function inner_boundary_vertices(graph::AbstractGraph, subgraph_vertices; dir=:out)
  V = vertextype(graph)
  subgraph_vertices_set = Set(subgraph_vertices)
  subgraph_complement = setdiff(Set(vertices(graph)), subgraph_vertices_set)
  inner_boundary_vs = Vector{V}()
  for subgraph_vertex in subgraph_vertices_set
    for subgraph_vertex_neighbor in _neighbors(graph, subgraph_vertex; dir)
      if subgraph_vertex_neighbor ∈ subgraph_complement
        push!(inner_boundary_vs, subgraph_vertex)
        break
      end
    end
  end
  return inner_boundary_vs
end

# https://en.wikipedia.org/wiki/Boundary_(graph_theory)
# See implementation of `Graphs.neighborhood_dists` as a reference.
function outer_boundary_vertices(graph::AbstractGraph, subgraph_vertices; dir=:out)
  V = vertextype(graph)
  subgraph_vertices_set = Set(subgraph_vertices)
  subgraph_complement = setdiff(Set(vertices(graph)), subgraph_vertices_set)
  outer_boundary_vs = Set{V}()
  for subgraph_vertex in subgraph_vertices_set
    for subgraph_vertex_neighbor in _neighbors(graph, subgraph_vertex; dir)
      if subgraph_vertex_neighbor ∈ subgraph_complement
        push!(outer_boundary_vs, subgraph_vertex_neighbor)
      end
    end
  end
  return [v for v in outer_boundary_vs]
end

function boundary_vertices(graph::AbstractGraph, subgraph_vertices; dir=:out)
  return inner_boundary_vertices(graph, subgraph_vertices; dir)
end
