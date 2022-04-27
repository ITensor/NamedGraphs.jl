function vcat(graph1::AbstractGraph, graph2::AbstractGraph; kwargs...)
  return hvncat(1, graph1, graph2; kwargs...)
end

function hcat(graph1::AbstractGraph, graph2::AbstractGraph; kwargs...)
  return hvncat(2, graph1, graph2; kwargs...)
end

# TODO: define `disjoint_union(graphs...; dim::Int, new_dim_names)` to do a disjoint union
# of a number of graphs.
function disjoint_union(graph1::AbstractGraph, graph2::AbstractGraph; dim::Int=0, kwargs...)
  return hvncat(dim, graph1, graph2; kwargs...)
end

function ⊔(graph1::AbstractGraph, graph2::AbstractGraph; kwargs...)
  return disjoint_union(graph1, graph2; kwargs...)
end

# https://github.com/JuliaGraphs/Graphs.jl/issues/34
@traitfn function is_tree(graph::::(!IsDirected))
  return (ne(graph) == nv(graph) - 1) && is_connected(graph)
end

@traitfn function is_tree(graph::::IsDirected)
  return !is_cyclic(graph)
end

function incident_edges(graph::AbstractGraph, vertex...)
  return [
    edgetype(graph)(to_vertex(graph, vertex...), neighbor_vertex) for
    neighbor_vertex in neighbors(graph, vertex...)
  ]
end
