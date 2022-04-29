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

function post_order_dfs_vertices(graph::AbstractGraph, source_index1, source_index...)
  source_vertex = to_vertex(graph, source_index1, source_index...)
  # Outputs a rooted directed tree (https://en.wikipedia.org/wiki/Arborescence_(graph_theory))
  tree = dfs_tree(graph, source_vertex)
  return [node.vertex for node in PostOrderDFS(TreeGraph(tree, source_vertex))]
end

function post_order_dfs_edges(graph::AbstractGraph, source_index...)
  vertices = post_order_dfs_vertices(graph, source_index...)
  # Remove the root vertex
  pop!(vertices)
  return [edgetype(graph)(vertex => parent_vertex(tree, vertex)) for vertex in vertices]
end

@traitfn function is_leaf(graph::::(!IsDirected), vertex...)
  # @assert is_tree(graph)
  return isone(length(neighbors(graph, vertex...)))
end

# Get the leaf vertices of an undirected tree-like graph
@traitfn function leaf_vertices(graph::::(!IsDirected))
  # @assert is_tree(graph)
  return [vertex for vertex in vertices(graph) if isone(length(neighbors(graph, vertex)))]
end

#
# Rooted directed tree functions.
# [Rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree)
#

# Get the parent vertex of a vertex.
# Assumes the graph is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree)
@traitfn function parent_vertex(graph::::IsDirected, vertex...)
  # @assert is_tree(graph)
  return only(inneighbors(graph, vertex...))
end

# Get the children of a vertex.
# Assumes the graph is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree)
@traitfn function child_vertices(graph::::IsDirected, vertex...)
  # @assert is_tree(graph)
  return outneighbors(graph, vertex...)
end

@traitfn function is_leaf(graph::::IsDirected, vertex...)
  # @assert is_tree(graph)
  return isone(length(inneighbors(vertex...)))
end

# Get the leaf vertices of a directed tree-like graph.
# Assumes it is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree)
# with edges pointed away from the root. The root is the only vertex with out edges.
#
# Could also use `AbstractTrees` for this:
#
# root_index = findfirst(vertex -> length(outneighbors(vertex)) == length(neighbors(vertex)), vertices(graph))
# root = vertices(graph)[root_index]
# [node.vertex for node in Leaves(TreeGraph(tree, root))]
#
@traitfn function leaf_vertices(graph::::IsDirected)
  # @assert is_tree(graph)
  return [vertex for vertex in vertices(graph) if isone(length(inneighbors(vertex)))]
end
