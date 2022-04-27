abstract type AbstractNamedGraph{V} <: AbstractGraph{V} end

#
# Required for interface
#

vertices(graph::AbstractNamedGraph) = not_implemented()
parent_graph(graph::AbstractNamedGraph) = not_implemented()
vertex_to_parent_vertex(graph::AbstractNamedGraph) = not_implemented()
edgetype(graph::AbstractNamedGraph) = not_implemented()
is_directed(::Type{<:AbstractNamedGraph}) = not_implemented()

parent_graph_type(graph::AbstractNamedGraph) = typeof(parent_graph(graph))
parent_eltype(graph::AbstractNamedGraph) = eltype(parent_graph(graph))

# By default, assume `vertex_to_parent_vertex(graph)`
# returns a data structure that you index into to map
# from a vertex to a parent vertex.
function vertex_to_parent_vertex(graph::AbstractNamedGraph, vertex...)
  return vertex_to_parent_vertex(graph)[vertex...]
end

# Convert parent vertex to vertex.
# Use `vertices`, assumes `vertices` is indexed by a parent vertex (a Vector for linear indexed parent vertices, a dictionary in general).
function parent_vertex_to_vertex(graph::AbstractNamedGraph, parent_vertex)
  return vertices(graph)[parent_vertex]
end

# This should be overloaded for multi-dimensional indexing.
# Get the subset of vertices of the graph, for example
# for an input slice `subvertices(graph, "X", :)`.
function subvertices(graph::AbstractNamedGraph, vertices...)
  return not_implemented()
end

function subvertices(graph::AbstractNamedGraph{V}, vertices::Vector{V}) where {V}
  return vertices
end

# This is to handle `NamedDimGraph` where some of the dimensions
# that are not slices get dropped.
function sliced_subvertices(graph::AbstractNamedGraph, vertices...)
  return subvertices(graph, vertices...)
end

function vertices_to_parent_vertices(
  graph::AbstractNamedGraph{V}, vertices::Vector{V}
) where {V}
  return parent_eltype(graph)[vertex_to_parent_vertex(graph, vertex) for vertex in vertices]
end

eltype(g::AbstractNamedGraph{V}) where {V} = V

parent_vertices(graph::AbstractNamedGraph) = vertices(parent_graph(graph))
parent_edges(graph::AbstractNamedGraph) = edges(parent_graph(graph))
parent_edgetype(graph::AbstractNamedGraph) = edgetype(parent_graph(graph))

function edge_to_parent_edge(graph::AbstractNamedGraph, edge::AbstractEdge)
  parent_src = vertex_to_parent_vertex(graph, src(edge))
  parent_dst = vertex_to_parent_vertex(graph, dst(edge))
  return parent_edgetype(graph)(parent_src, parent_dst)
end

function edge_to_parent_edge(graph::AbstractNamedGraph, edge)
  return edge_to_parent_edge(graph, edgetype(graph)(edge))
end

# TODO: This is `O(nv(g))`, use `haskey(vertex_to_parent_vertex(g), v)` instead?
has_vertex(g::AbstractNamedGraph, v) = v in vertices(g)

function edges(graph::AbstractNamedGraph)
  vertex(parent_vertex) = vertices(graph)[parent_vertex]
  edge(parent_edge) = edgetype(graph)(vertex(src(parent_edge)), vertex(dst(parent_edge)))
  return map(edge, parent_edges(graph))
end

# TODO: write in terms of a generic function.
for f in [:outneighbors, :inneighbors, :all_neighbors, :neighbors]
  @eval begin
    function $f(graph::AbstractNamedGraph, vertex...)
      parent_vertices = $f(parent_graph(graph), vertex_to_parent_vertex(graph, vertex...))
      return [parent_vertex_to_vertex(graph, parent_vertex) for parent_vertex in parent_vertices]
    end

    # Ambiguity errors with Graphs.jl
    function $f(graph::AbstractNamedGraph, vertex::Integer)
      parent_vertices = $f(parent_graph(graph), vertex_to_parent_vertex(graph, vertex))
      return [parent_vertex_to_vertex(graph, parent_vertex) for parent_vertex in parent_vertices]
    end
  end
end

function add_edge!(graph::AbstractNamedGraph, edge)
  add_edge!(parent_graph(graph), edge_to_parent_edge(graph, edge))
  return graph
end

function rem_edge!(graph::AbstractNamedGraph, edge)
  rem_edge!(parent_graph(graph), edge_to_parent_edge(graph, edge))
  return graph
end

function has_edge(graph::AbstractNamedGraph, edge::AbstractNamedEdge)
  return has_edge(parent_graph(graph), edge_to_parent_edge(graph, edge))
end

# handles single-argument edge constructors such as pairs and tuples
has_edge(g::AbstractNamedGraph, x) = has_edge(g, edgetype(g)(x))
add_edge!(g::AbstractNamedGraph, x) = add_edge!(g, edgetype(g)(x))

# handles two-argument edge constructors like src,dst
has_edge(g::AbstractNamedGraph, x, y) = has_edge(g, edgetype(g)(x, y))
add_edge!(g::AbstractNamedGraph, x, y) = add_edge!(g, edgetype(g)(x, y))

function add_vertex!(graph::AbstractNamedGraph, v...)
  # Convert to a vertex of the graph type
  # For example, for MultiDimNamedGraph, this does:
  #
  # to_vertex(graph, "X") # ("X",)
  # to_vertex(graph, "X", 1) # ("X", 1)
  # to_vertex(graph, ("X", 1)) # ("X", 1)
  #
  # For general graph types it is:
  #
  # to_vertex(graph, "X") # "X"
  vertex = to_vertex(graph, v...)
  if vertex ∈ vertices(graph)
    throw(ArgumentError("Duplicate vertices are not allowed"))
  end
  add_vertex!(parent_graph(graph))
  # Update the vertex list
  push!(vertices(graph), vertex)
  # Update the reverse map
  insert!(vertex_to_parent_vertex(graph), vertex, last(parent_vertices(graph)))
  return graph
end

function rem_vertex!(graph::AbstractNamedGraph, v...)
  vertex = to_vertex(graph, v...)
  rem_vertex!(parent_graph(graph), vertex_to_parent_vertex(graph, vertex))
  deleteat!(vertices(graph), findfirst(==(vertex), vertices(graph)))
  delete!(vertex_to_parent_vertex(graph), vertex)
  return graph
end

function add_vertices!(graph::AbstractNamedGraph, vs::Vector)
  for vertex in vs
    add_vertex!(graph, vertex)
  end
  return graph
end

function getindex(graph::AbstractNamedGraph, sub_vertices...)
  graph_subvertices = subvertices(graph, sub_vertices...)
  graph_sliced_subvertices = sliced_subvertices(graph, sub_vertices...)
  parent_subgraph_vertices = vertices_to_parent_vertices(graph, graph_subvertices)
  parent_subgraph, _ = induced_subgraph(parent_graph(graph), parent_subgraph_vertices)
  return typeof(graph)(parent_subgraph, graph_sliced_subvertices)
end

is_directed(graph::AbstractNamedGraph) = is_directed(parent_graph(graph))

is_connected(graph::AbstractNamedGraph) = is_connected(parent_graph(graph))

is_cyclic(graph::AbstractNamedGraph) = is_cyclic(parent_graph(graph))

# Rename `disjoint_union`: https://networkx.org/documentation/stable/reference/algorithms/operators.html
function blockdiag(graph1::AbstractNamedGraph, graph2::AbstractNamedGraph)
  new_parent_graph = blockdiag(parent_graph(graph1), parent_graph(graph2))
  new_vertices = vcat(vertices(graph1), vertices(graph2))
  return AbstractNamedGraph(new_parent_graph, new_vertices)
end

nv(graph::AbstractNamedGraph, args...) = nv(parent_graph(graph), args...)
ne(graph::AbstractNamedGraph, args...) = ne(parent_graph(graph), args...)
function adjacency_matrix(graph::AbstractNamedGraph, args...)
  return adjacency_matrix(parent_graph(graph), args...)
end

# 
# Graph traversals
#

bfs_tree(g::AbstractNamedGraph, s...; kwargs...) = tree(g, bfs_parents(g, s...; kwargs...))

# Disambiguation from Graphs.bfs_tree
bfs_tree(g::AbstractNamedGraph, s::Integer; kwargs...) = bfs_tree(g, tuple(s); kwargs...)

function bfs_parents(graph::AbstractNamedGraph, s...; kwargs...)
  parent_bfs_parents = bfs_parents(parent_graph(graph), vertex_to_parent_vertex(graph)[s...]; kwargs...)
  return [vertices(graph)[parent_vertex] for parent_vertex in parent_bfs_parents]
end

dfs_tree(g::AbstractNamedGraph, s...; kwargs...) = tree(g, dfs_parents(g, s...; kwargs...))

# Disambiguation from Graphs.dfs_tree
dfs_tree(g::AbstractNamedGraph, s::Integer; kwargs...) = dfs_tree(g, tuple(s); kwargs...)

function dfs_parents(graph::AbstractNamedGraph, s...; kwargs...)
  parent_dfs_parents = dfs_parents(parent_graph(graph), vertex_to_parent_vertex(graph)[s...]; kwargs...)
  return [vertices(graph)[parent_vertex] for parent_vertex in parent_dfs_parents]
end

#
# Printing
#

function show(io::IO, mime::MIME"text/plain", graph::AbstractNamedGraph)
  println(io, "$(typeof(graph)) with $(nv(graph)) vertices:")
  show(io, mime, vertices(graph))
  println(io, "\n")
  println(io, "and $(ne(graph)) edge(s):")
  for e in edges(graph)
    show(io, mime, e)
    println(io)
  end
  return nothing
end

show(io::IO, graph::AbstractNamedGraph) = show(io, MIME"text/plain"(), graph)
