# Used for tree iteration.
# Assumes the graph is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree).
struct TreeGraph{G,V}
  graph::G
  vertex::V
end
function AbstractTrees.children(t::TreeGraph)
  return [TreeGraph(t.graph, vertex) for vertex in child_vertices(t.graph, t.vertex)]
end
AbstractTrees.printnode(io::IO, t::TreeGraph) = print(io, t.vertex)

#
# Graph unions
#

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
function is_tree(graph::AbstractGraph)
  return (ne(graph) == nv(graph) - 1) && is_connected(graph)
end

function incident_edges(graph::AbstractGraph, vertex...)
  return [
    edgetype(graph)(to_vertex(graph, vertex...), neighbor_vertex) for
    neighbor_vertex in neighbors(graph, vertex...)
  ]
end

# Get the leaf vertices of a tree-like graph
# 
# For the directed case, could also use `AbstractTrees`:
#
# root_index = findfirst(vertex -> length(outneighbors(vertex)) == length(neighbors(vertex)), vertices(graph))
# root = vertices(graph)[root_index]
# [node.vertex for node in Leaves(TreeGraph(graph, root))]
#
function leaf_vertices(graph::AbstractGraph)
  # @assert is_tree(graph)
  return filter(v -> is_leaf(graph, v...), vertices(graph))
end

#
# Graph iteration
#

@traitfn function post_order_dfs_vertices(graph::::(!IsDirected), root_vertex...)
  dfs_tree_graph = dfs_tree(graph, root_vertex...)
  return post_order_dfs_vertices(dfs_tree_graph, root_vertex...)
end

@traitfn function post_order_dfs_edges(graph::::(!IsDirected), root_vertex...)
  dfs_tree_graph = dfs_tree(graph, root_vertex...)
  return post_order_dfs_edges(dfs_tree_graph, root_vertex...)
end

@traitfn function is_leaf(graph::::(!IsDirected), vertex...)
  # @assert is_tree(graph)
  return isone(length(neighbors(graph, vertex...)))
end

# Paths for undirected tree-like graphs
@traitfn function vertex_path(graph::::(!IsDirected), s, t)
  dfs_tree_graph = dfs_tree(graph, t...)
  return vertex_path(dfs_tree_graph, s, t)
end

@traitfn function edge_path(graph::::(!IsDirected), s, t)
  dfs_tree_graph = dfs_tree(graph, t...)
  return edge_path(dfs_tree_graph, s, t)
end

#
# Rooted directed tree functions.
# [Rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree)
#

# Get the parent vertex of a vertex.
# Assumes the graph is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree)
@traitfn function parent_vertex(graph::::IsDirected, vertex...)
  # @assert is_tree(graph)
  in_neighbors = inneighbors(graph, vertex...)
  isempty(in_neighbors) && return nothing
  return only(in_neighbors)
end

# Returns the edge directed **towards the parent/root vertex**!
@traitfn function parent_edge(graph::::IsDirected, vertex...)
  # @assert is_tree(graph)
  parent = parent_vertex(graph, vertex...)
  isnothing(parent) && return nothing
  return edgetype(graph)(vertex..., parent)
end

# Get the children of a vertex.
# Assumes the graph is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree)
@traitfn function child_vertices(graph::::IsDirected, vertex...)
  # @assert is_tree(graph)
  return outneighbors(graph, vertex...)
end

# Get the edges from the input vertex towards the child vertices.
@traitfn function child_edges(graph::::IsDirected, vertex...)
  # @assert is_tree(graph)
  return [
    edgetype(graph)(vertex..., child_vertex) for
    child_vertex in child_vertices(graph, vertex...)
  ]
end

# Check if a vertex is a leaf.
# Assumes the graph is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree)
@traitfn function is_leaf(graph::::IsDirected, vertex...)
  # @assert is_tree(graph)
  return isempty(outneighbors(graph, vertex...))
end

# Traverse the tree using a [post-order depth-first search](https://en.wikipedia.org/wiki/Tree_traversal#Depth-first_search), returning the vertices.
# Assumes the graph is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree)
@traitfn function post_order_dfs_vertices(graph::::IsDirected, root_index1, root_index...)
  # @assert is_tree(graph)
  root_vertex = to_vertex(graph, root_index1, root_index...)
  # Outputs a rooted directed tree (https://en.wikipedia.org/wiki/Arborescence_(graph_theory))
  return [node.vertex for node in PostOrderDFS(TreeGraph(graph, root_vertex))]
end

# Traverse the tree using a [post-order depth-first search](https://en.wikipedia.org/wiki/Tree_traversal#Depth-first_search), returning the edges where the source is the current vertex and the destination is the parent vertex.
# Assumes the graph is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree).
# Returns a list of edges directed **towards the root vertex**!
@traitfn function post_order_dfs_edges(graph::::IsDirected, root_vertex...)
  # @assert is_tree(graph)
  vertices = post_order_dfs_vertices(graph, root_vertex...)
  # Remove the root vertex
  pop!(vertices)
  return [parent_edge(graph, vertex) for vertex in vertices]
end

# Paths for directed tree-like graphs
@traitfn function vertex_path(graph::::IsDirected, s, t)
  vertices = eltype(graph)[s]
  while vertices[end] != t
    parent = parent_vertex(graph, vertices[end]...)
    isnothing(parent) && return nothing
    push!(vertices, parent)
  end
  return vertices
end

@traitfn function edge_path(graph::::IsDirected, s, t)
  vertices = vertex_path(graph, s, t)
  isnothing(vertices) && return nothing
  pop!(vertices)
  return [edgetype(graph)(vertex, parent_vertex(graph, vertex...)) for vertex in vertices]
end
