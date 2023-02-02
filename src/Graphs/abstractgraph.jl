directed_graph(::Type{<:AbstractGraph}) = error("Not implemented")
undirected_graph(::Type{<:AbstractGraph}) = error("Not implemented")
# TODO: Implement generic version for `IsDirected`
# directed_graph(G::Type{IsDirected}) = G

@traitfn directed_graph(graph::::IsDirected) = graph

convert_vertextype(::Type{V}, graph::AbstractGraph{V}) where {V} = graph
function convert_vertextype(V::Type, graph::AbstractGraph)
  return not_implemented()
end

# TODO: Handle metadata in a generic way
@traitfn function directed_graph(graph::::(!IsDirected))
  digraph = directed_graph(typeof(graph))()
  for v in vertices(graph)
    add_vertex!(digraph, v)
  end
  for e in edges(graph)
    add_edge!(digraph, e)
    add_edge!(digraph, reverse(e))
  end
  return digraph
end

@traitfn function directed_graph(graph::AbstractSimpleGraph::(!IsDirected))
  digraph = directed_graph(typeof(graph))()
  for v in vertices(graph)
    add_vertex!(digraph)
  end
  for e in edges(graph)
    add_edge!(digraph, e)
    add_edge!(digraph, reverse(e))
  end
  return digraph
end

@traitfn undirected_graph(graph::::(!IsDirected)) = graph

# TODO: Handle metadata in a generic way
# Must have the same argument name as:
# @traitfn undirected_graph(graph::::(!IsDirected))
# to avoid method overwrite warnings, see:
# https://github.com/mauro3/SimpleTraits.jl#method-overwritten-warnings
@traitfn function undirected_graph(graph::::IsDirected)
  undigraph = undirected_graph(typeof(graph))(vertices(graph))
  for e in edges(graph)
    # TODO: Check for repeated edges?
    add_edge!(undigraph, e)
  end
  return undigraph
end

# Similar to `eltype`, but `eltype` doesn't work on types
vertextype(::Type{<:AbstractGraph{V}}) where {V} = V
vertextype(graph::AbstractGraph) = vertextype(typeof(graph))

# Function `f` maps original vertices `vᵢ` of `g`
# to new vertices `f(vᵢ)` of the output graph.
function rename_vertices(f::Function, g::AbstractGraph)
  return set_vertices(g, f.(vertices(g)))
end

function rename_vertices(g::AbstractGraph, name_map)
  return rename_vertices(v -> name_map[v], g)
end

function permute_vertices(graph::AbstractGraph, permutation::Vector)
  return subgraph(graph, vertices(graph)[permutation])
end

# Uniform interface for `outneighbors`, `inneighbors`, and `all_neighbors`
function _neighbors(graph::AbstractGraph, vertex; dir=:out)
  if dir == :out
    return outneighbors(graph, vertex)
  elseif dir == :in
    return inneighbors(graph, vertex)
  elseif dir == :both
    return all_neighbors(graph, vertex)
  end
  return error(
    "`_neighbors(graph::AbstractGraph, vertex; dir)` with `dir = $(dir) not implemented. Use either `dir = :out`, `dir = :in`, or `dir = :both`.",
  )
end

# Returns just the edges of a directed graph,
# but both edge directions of an undirected graph.
# TODO: Move to NamedGraphs.jl
@traitfn function all_edges(g::::IsDirected)
  return edges(g)
end

@traitfn function all_edges(g::::(!IsDirected))
  e = edges(g)
  return Iterators.flatten(zip(e, reverse.(e)))
end

# Alternative syntax to `getindex` for getting a subgraph
function subgraph(graph::AbstractGraph, subvertices::Vector)
  return induced_subgraph(graph, subvertices)[1]
end

function subgraph(f::Function, graph::AbstractGraph)
  return induced_subgraph(graph, filter(f, vertices(graph)))[1]
end

function degrees(graph::AbstractGraph, vertices=vertices(graph))
  return map(vertex -> degree(graph, vertex), vertices)
end

function indegrees(graph::AbstractGraph, vertices=vertices(graph))
  return map(vertex -> indegree(graph, vertex), vertices)
end

function outdegrees(graph::AbstractGraph, vertices=vertices(graph))
  return map(vertex -> outdegree(graph, vertex), vertices)
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

#
# Graph unions
#

# https://en.wikipedia.org/wiki/Disjoint_union
# Input maps the new index being appended to the vertices
# to the associated graph.
function disjoint_union(graphs::Dictionary{<:Any,<:AbstractGraph})
  return union((rename_vertices(v -> (v, i), graphs[i]) for i in keys(graphs))...)
end

function disjoint_union(graphs::Vector{<:AbstractGraph})
  return disjoint_union(Dictionary(graphs))
end

disjoint_union(graph::AbstractGraph) = graph

function disjoint_union(graph1::AbstractGraph, graphs_tail::AbstractGraph...)
  return disjoint_union(Dictionary([graph1, graphs_tail...]))
end

function disjoint_union(pairs::Pair...)
  return disjoint_union([pairs...])
end

function disjoint_union(iter::Vector{<:Pair})
  return disjoint_union(dictionary(iter))
end

function ⊔(graphs...; kwargs...)
  return disjoint_union(graphs...; kwargs...)
end

# vcat, hcat, hvncat
# function vcat(graph1::AbstractGraph, graph2::AbstractGraph; kwargs...)
#   return hvncat(1, graph1, graph2; kwargs...)
# end
# 
# function hcat(graph1::AbstractGraph, graph2::AbstractGraph; kwargs...)
#   return hvncat(2, graph1, graph2; kwargs...)
# end
# 
# # TODO: define `disjoint_union(graphs...; dim::Int, new_dim_names)` to do a disjoint union
# # of a number of graphs.
# function disjoint_union(graph1::AbstractGraph, graph2::AbstractGraph; dim::Int=0, kwargs...)
#   return hvncat(dim, graph1, graph2; kwargs...)
# end

# https://github.com/JuliaGraphs/Graphs.jl/issues/34
function is_tree(graph::AbstractGraph)
  return (ne(graph) == nv(graph) - 1) && is_connected(graph)
end

"""
TODO: Make this more sophisticated, check that
only two vertices have degree 1 and none have
degree 0, meaning it is a path/linear graph:

https://en.wikipedia.org/wiki/Path_graph

but not a path/linear forest:

https://en.wikipedia.org/wiki/Linear_forest
"""
function is_path_graph(graph::AbstractGraph)
  # Maximum degree
  return Δ(graph) == 2
end

function out_incident_edges(graph::AbstractGraph, vertex)
  return [
    edgetype(graph)(vertex, neighbor_vertex) for
    neighbor_vertex in outneighbors(graph, vertex)
  ]
end

function in_incident_edges(graph::AbstractGraph, vertex)
  return [
    edgetype(graph)(neighbor_vertex, vertex) for
    neighbor_vertex in inneighbors(graph, vertex)
  ]
end

# TODO: Only return one set of `:out` edges for undirected graphs if `dir=:both`.
function all_incident_edges(graph::AbstractGraph, vertex)
  return out_incident_edges(graph, vertex) ∪ in_incident_edges(graph, vertex)
end

# TODO: Same as `edges(subgraph(graph, [vertex; neighbors(graph, vertex)]))`.
# TODO: Only return one set of `:out` edges for undirected graphs if `dir=:both`.
"""
    incident_edges(graph::AbstractGraph, vertex; dir=:out)

Edges incident to the vertex `vertex`.

`dir ∈ (:in, :out, :both)`, defaults to `:out`.

For undirected graphs, returns all incident edges.

Like: https://juliagraphs.org/Graphs.jl/v1.7/algorithms/linalg/#Graphs.LinAlg.adjacency_matrix
"""
function incident_edges(graph::AbstractGraph, vertex; dir=:out)
  if dir == :out
    return out_incident_edges(graph, vertex)
  elseif dir == :in
    return in_incident_edges(graph, vertex)
  elseif dir == :both
    return all_incident_edges(graph, vertex)
  end
  return error("dir = $dir not supported.")
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
  return filter(v -> is_leaf(graph, v), vertices(graph))
end

#
# Graph iteration
#

@traitfn function post_order_dfs_vertices(graph::::(!IsDirected), root_vertex)
  dfs_tree_graph = dfs_tree(graph, root_vertex)
  return post_order_dfs_vertices(dfs_tree_graph, root_vertex)
end

@traitfn function post_order_dfs_edges(graph::::(!IsDirected), root_vertex)
  dfs_tree_graph = dfs_tree(graph, root_vertex)
  return post_order_dfs_edges(dfs_tree_graph, root_vertex)
end

@traitfn function is_leaf(graph::::(!IsDirected), vertex)
  # @assert is_tree(graph)
  return isone(length(neighbors(graph, vertex)))
end

# Paths for undirected tree-like graphs
# TODO: Use `a_star`.
@traitfn function vertex_path(graph::::(!IsDirected), s, t)
  dfs_tree_graph = dfs_tree(graph, t)
  return vertex_path(dfs_tree_graph, s, t)
end

# TODO: Use `a_star`.
@traitfn function edge_path(graph::::(!IsDirected), s, t)
  dfs_tree_graph = dfs_tree(graph, t)
  return edge_path(dfs_tree_graph, s, t)
end

#
# Rooted directed tree functions.
# [Rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree)
#

# Get the parent vertex of a vertex.
# Assumes the graph is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree)
@traitfn function parent_vertex(graph::::IsDirected, vertex)
  # @assert is_tree(graph)
  in_neighbors = inneighbors(graph, vertex)
  isempty(in_neighbors) && return nothing
  return only(in_neighbors)
end

# Returns the edge directed **towards the parent/root vertex**!
@traitfn function parent_edge(graph::::IsDirected, vertex)
  # @assert is_tree(graph)
  parent = parent_vertex(graph, vertex)
  isnothing(parent) && return nothing
  return edgetype(graph)(vertex, parent)
end

# Get the children of a vertex.
# Assumes the graph is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree)
@traitfn function child_vertices(graph::::IsDirected, vertex)
  # @assert is_tree(graph)
  return outneighbors(graph, vertex)
end

# Get the edges from the input vertex towards the child vertices.
@traitfn function child_edges(graph::::IsDirected, vertex)
  # @assert is_tree(graph)
  return [
    edgetype(graph)(vertex, child_vertex) for child_vertex in child_vertices(graph, vertex)
  ]
end

# Check if a vertex is a leaf.
# Assumes the graph is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree)
@traitfn function is_leaf(graph::::IsDirected, vertex)
  # @assert is_tree(graph)
  return isempty(outneighbors(graph, vertex))
end

# Traverse the tree using a [post-order depth-first search](https://en.wikipedia.org/wiki/Tree_traversal#Depth-first_search), returning the vertices.
# Assumes the graph is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree)
@traitfn function post_order_dfs_vertices(graph::::IsDirected, root_vertex)
  # @assert is_tree(graph)
  # Outputs a rooted directed tree (https://en.wikipedia.org/wiki/Arborescence_(graph_theory))
  return [node.vertex for node in PostOrderDFS(TreeGraph(graph, root_vertex))]
end

# Traverse the tree using a [post-order depth-first search](https://en.wikipedia.org/wiki/Tree_traversal#Depth-first_search), returning the edges where the source is the current vertex and the destination is the parent vertex.
# Assumes the graph is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree).
# Returns a list of edges directed **towards the root vertex**!
@traitfn function post_order_dfs_edges(graph::::IsDirected, root_vertex)
  # @assert is_tree(graph)
  vertices = post_order_dfs_vertices(graph, root_vertex)
  # Remove the root vertex
  pop!(vertices)
  return [parent_edge(graph, vertex) for vertex in vertices]
end

# Paths for directed tree-like graphs
# TODO: Use `a_star`, make specialized versions:
# `vertex_path(graph::::IsTree, ...)`
# or
# `tree_vertex_path(graph, ...)`
@traitfn function vertex_path(graph::::IsDirected, s, t)
  # @assert is_tree(graph)
  vertices = eltype(graph)[s]
  while vertices[end] != t
    parent = parent_vertex(graph, vertices[end])
    isnothing(parent) && return nothing
    push!(vertices, parent)
  end
  return vertices
end

# TODO: Use `a_star`, make specialized versions:
# `vertex_path(graph::::IsTree, ...)`
# or
# `tree_vertex_path(graph, ...)`
@traitfn function edge_path(graph::::IsDirected, s, t)
  # @assert is_tree(graph)
  vertices = vertex_path(graph, s, t)
  isnothing(vertices) && return nothing
  pop!(vertices)
  return [edgetype(graph)(vertex, parent_vertex(graph, vertex)) for vertex in vertices]
end

function mincut_partitions(graph::AbstractGraph, distmx=weights(graph))
  parts = groupfind(first(mincut(graph, distmx)))
  return parts[1], parts[2]
end

"""Remove a list of edges from a graph g"""
function rem_edges!(g::AbstractGraph, edges)
  for e in edges
    rem_edge!(g, e)
  end
  return g
end

function rem_edges(g::AbstractGraph, edges)
  g = copy(g)
  rem_edges!(g, edges)
  return g
end

"""Add a list of edges to a graph g"""
function add_edges!(g::AbstractGraph, edges)
  for e in edges
    add_edge!(g, e)
  end
  return g
end

function add_edges(g::AbstractGraph, edges)
  g = copy(g)
  add_edges!(g, edges)
  return g
end
