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

# Get the parent vertex of a vertex.
# Assumes the graph is locally tree-like (the vertex has only
# one incoming edge).
function parent_vertex(graph::AbstractGraph, vertex...)
  return only(inneighbors(graph, vertex...))
end

function child_vertices(graph::AbstractGraph, vertex...)
  return outneighbors(graph, vertex...)
end

# Used for tree iteration.
# Assume that `graph` represents a rooted directed tree (https://en.wikipedia.org/wiki/Arborescence_(graph_theory))
struct TreeGraph{G,V}
  graph::G
  vertex::V
end
function AbstractTrees.children(t::TreeGraph)
  return [TreeGraph(t.graph, vertex) for vertex in child_vertices(t.graph, t.vertex)]
end
AbstractTrees.printnode(io::IO, t::TreeGraph) = print(io, t.vertex)

function post_order_dfs_edges(graph::AbstractGraph, source_index...)
  source_vertex = to_vertex(graph, source_index...)
  # Outputs a rooted directed tree (https://en.wikipedia.org/wiki/Arborescence_(graph_theory))
  tree = dfs_tree(graph, source_vertex)
  vertices = [node.vertex for node in PostOrderDFS(TreeGraph(tree, source_vertex))]
  # Remove the source node
  pop!(vertices)
  return [edgetype(graph)(vertex => parent_vertex(tree, vertex)) for vertex in vertices]
end

function leaf_vertices(graph::AbstractGraph, source_index...)
  source_vertex = to_vertex(graph, source_index...)
  # Outputs a rooted directed tree (https://en.wikipedia.org/wiki/Arborescence_(graph_theory))
  tree = dfs_tree(graph, source_vertex)
  return [node.vertex for node in Leaves(TreeGraph(tree, source_vertex))]
end
