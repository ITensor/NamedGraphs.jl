abstract type AbstractNamedGraph{V} <: AbstractGraph{V} end

#
# Required for interface
#

vertices(graph::AbstractNamedGraph) = not_implemented()
parent_graph(graph::AbstractNamedGraph) = not_implemented()

# TODO: Require this for the interface, or implement as:
# typeof(parent_graph(graph))
# ?
parent_graph_type(graph::AbstractNamedGraph) = not_implemented()

parent_vertextype(graph::AbstractNamedGraph) = vertextype(parent_graph(graph))

# Convert vertex to parent vertex
# Inverse map of `parent_vertex_to_vertex`.
vertex_to_parent_vertex(graph::AbstractNamedGraph, vertex) = not_implemented()

# Convert parent vertex to vertex.
# Use `vertices`, assumes `vertices` is indexed by a parent vertex (a Vector for linear indexed parent vertices, a dictionary in general).
function parent_vertex_to_vertex(graph::AbstractNamedGraph, parent_vertex)
  return vertices(graph)[parent_vertex]
end

# Convenient shorthands for using in higher order functions like `map`.
vertex_to_parent_vertex(graph::AbstractNamedGraph) = Base.Fix1(vertex_to_parent_vertex, graph)
parent_vertex_to_vertex(graph::AbstractNamedGraph) = Base.Fix1(parent_vertex_to_vertex, graph)

# TODO: rename `edge_type`?
edgetype(graph::AbstractNamedGraph) = not_implemented()
directed_graph(G::Type{<:AbstractNamedGraph}) = not_implemented()
undirected_graph(G::Type{<:AbstractNamedGraph}) = not_implemented()

# In terms of `parent_graph_type`
# is_directed(::Type{<:AbstractNamedGraph}) = not_implemented()

convert_vertextype(::Type, ::AbstractNamedGraph) = not_implemented()

# TODO: implement as:
#
# graph = set_parent_graph(graph, copy(parent_graph(graph)))
# graph = set_vertices(graph, copy(vertices(graph)))
#
# or:
#
# graph_copy = similar(typeof(graph))(vertices(graph))
# for e in edges(graph)
#   add_edge!(graph_copy, e)
# end
copy(graph::AbstractNamedGraph) = not_implemented()

zero(G::Type{<:AbstractNamedGraph}) = G()

# TODO: Implement using `copyto!`?
function directed_graph(graph::AbstractNamedGraph)
  digraph = directed_graph(typeof(graph))(vertices(graph))
  for e in edges(graph)
    add_edge!(digraph, e)
    add_edge!(digraph, reverse(e))
  end
  return digraph
end

# Default, can overload
eltype(graph::AbstractNamedGraph) = eltype(vertices(graph))

parent_eltype(graph::AbstractNamedGraph) = eltype(parent_graph(graph))

# This should be overloaded for multi-dimensional indexing.
# Get the subset of vertices of the graph, for example
# for an input slice `subvertices(graph, "X", :)`.
function subvertices(graph::AbstractNamedGraph, vertices)
  return not_implemented()
end

function subvertices(graph::AbstractNamedGraph{V}, vertices::Vector{V}) where {V}
  return vertices
end

function vertices_to_parent_vertices(
  graph::AbstractNamedGraph, vertices
)
  return map(vertex_to_parent_vertex(graph), vertices)
end

function vertices_to_parent_vertices(graph::AbstractNamedGraph)
  return Base.Fix1(vertices_to_parent_vertices, graph)
end

function parent_vertices_to_vertices(
  graph::AbstractNamedGraph, parent_vertices
)
  return map(parent_vertex_to_vertex(graph), parent_vertices)
end

function parent_vertices_to_vertices(graph::AbstractNamedGraph)
  return Base.Fix1(parent_vertices_to_vertices, graph)
end

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

edge_to_parent_edge(graph::AbstractNamedGraph) = Base.Fix1(edge_to_parent_edge, graph)

function edges_to_parent_edges(graph::AbstractNamedGraph, edges)
  return map(edge_to_parent_edge(graph), edges)
end

function parent_edge_to_edge(graph::AbstractNamedGraph, parent_edge::AbstractEdge)
  source = parent_vertex_to_vertex(graph, src(parent_edge))
  destination = parent_vertex_to_vertex(graph, dst(parent_edge))
  return edgetype(graph)(source, destination)
end

function parent_edge_to_edge(graph::AbstractNamedGraph, parent_edge)
  return parent_edge_to_edge(graph, parent_edgetype(parent_edge))
end

parent_edge_to_edge(graph::AbstractNamedGraph) = Base.Fix1(parent_edge_to_edge, graph)

function parent_edges_to_edges(graph::AbstractNamedGraph, parent_edges)
  return map(parent_edge_to_edge(graph), parent_edges)
end

# TODO: This is `O(nv(g))`, use `haskey(vertex_to_parent_vertex(g), v)` instead?
has_vertex(g::AbstractNamedGraph, v) = v in vertices(g)

function edges(graph::AbstractNamedGraph)
  return parent_edges_to_edges(graph, parent_edges(graph))
end

# TODO: write in terms of a generic function.
for f in [:outneighbors, :inneighbors, :all_neighbors, :neighbors]
  @eval begin
    function $f(graph::AbstractNamedGraph, vertex)
      parent_vertices = $f(parent_graph(graph), vertex_to_parent_vertex(graph, vertex))
      return parent_vertices_to_vertices(graph, parent_vertices)
    end

    # Ambiguity errors with Graphs.jl
    function $f(graph::AbstractNamedGraph, vertex::Integer)
      parent_vertices = $f(parent_graph(graph), vertex_to_parent_vertex(graph, vertex))
      return parent_vertices_to_vertices(graph, parent_vertices)
    end
  end
end

common_neighbors(g::AbstractNamedGraph, u, v) = intersect(neighbors(g, u), neighbors(g, v))

indegree(graph::AbstractNamedGraph, vertex) = length(inneighbors(graph, vertex))
outdegree(graph::AbstractNamedGraph, vertex) = length(outneighbors(graph, vertex))

@traitfn degree(graph::AbstractNamedGraph::IsDirected, vertex) = indegree(graph, vertex) + outdegree(graph, vertex)
@traitfn degree(graph::AbstractNamedGraph::(!IsDirected), vertex) = indegree(graph, vertex)

function degree_histogram(g::AbstractNamedGraph, degfn=degree)
  hist = Dictionary{Int,Int}()
  for v in vertices(g)        # minimize allocations by
    for d in degfn(g, v)    # iterating over vertices
      set!(hist, d, get(hist, d, 0) + 1)
    end
  end
  return hist
end

function dist_matrix_to_parent_dist_matrix(graph::AbstractNamedGraph, distmx)
  not_implemented()
end

function dist_matrix_to_parent_dist_matrix(graph::AbstractNamedGraph, distmx::Graphs.DefaultDistance)
  return distmx
end

function neighborhood(graph::AbstractNamedGraph, vertex, d, distmx=weights(graph); dir=:out)
  parent_distmx = dist_matrix_to_parent_dist_matrix(graph, distmx)
  parent_vertices = neighborhood(parent_graph(graph), vertex_to_parent_vertex(graph, vertex), d, parent_distmx; dir)
  return [
    parent_vertex_to_vertex(graph, parent_vertex) for parent_vertex in parent_vertices
  ]
end

function neighborhood_dists(graph::AbstractNamedGraph, vertex, d, distmx=weights(graph); dir=:out)
  parent_distmx = dist_matrix_to_parent_dist_matrix(graph, distmx)
  parent_vertices_and_dists = neighborhood_dists(parent_graph(graph), vertex_to_parent_vertex(graph, vertex), d, parent_distmx; dir)
  return [
    (parent_vertex_to_vertex(graph, parent_vertex), dist) for (parent_vertex, dist) in parent_vertices_and_dists
  ]
end

function a_star(
  graph::AbstractNamedGraph,
  source,
  destination,
  distmx=weights(graph),
  heuristic::Function=(v -> zero(eltype(distmx))),
  edgetype_to_return=edgetype(graph),
)
  parent_distmx = dist_matrix_to_parent_dist_matrix(graph, distmx)
  parent_shortest_path = a_star(
    parent_graph(graph),
    vertex_to_parent_vertex(graph, source),
    vertex_to_parent_vertex(graph, destination),
    dist_matrix_to_parent_dist_matrix(graph, distmx),
    heuristic,
    SimpleEdge,
  )
  return parent_edges_to_edges(graph, parent_shortest_path)
end

function spfa_shortest_paths(graph::AbstractNamedGraph, vertex, distmx=weights(graph))
  parent_distmx = dist_matrix_to_parent_dist_matrix(graph, distmx)
  parent_shortest_paths = spfa_shortest_paths(parent_graph(graph), vertex_to_parent_vertex(graph, vertex), parent_distmx)
  return Dictionary(vertices(graph), parent_shortest_paths)
end

function boruvka_mst(
  g::AbstractNamedGraph,
  distmx::AbstractMatrix{<:Real}=weights(g);
  minimize=true,
) 
  parent_mst, weights = boruvka_mst(parent_graph(g), distmx; minimize)
  return parent_edges_to_edges(g, parent_mst), weights
end

function kruskal_mst(
  g::AbstractNamedGraph,
  distmx::AbstractMatrix{<:Real}=weights(g);
  minimize=true,
)
  parent_mst = kruskal_mst(parent_graph(g), distmx; minimize)
  return parent_edges_to_edges(g, parent_mst)
end

function prim_mst(
  g::AbstractNamedGraph,
  distmx::AbstractMatrix{<:Real}=weights(g),
)
  parent_mst = prim_mst(parent_graph(g), distmx)
  return parent_edges_to_edges(g, parent_mst)
end

for f in [
  :bellman_ford_shortest_paths,
  :desopo_pape_shortest_paths,
  :dijkstra_shortest_paths,
  :floyd_warshall_shortest_paths,
  :johnson_shortest_paths,
  :yen_k_shortest_paths,
]
  @eval begin
    function $f(graph::AbstractNamedGraph, args...; kwargs...)
      return not_implemented()
    end
  end
end

function add_edge!(graph::AbstractNamedGraph, edge::AbstractEdge)
  add_edge!(parent_graph(graph), edge_to_parent_edge(graph, edge))
  return graph
end

# handles single-argument edge constructors such as pairs and tuples
add_edge!(g::AbstractNamedGraph, edge) = add_edge!(g, edgetype(g)(edge))
add_edge!(g::AbstractNamedGraph, src, dst) = add_edge!(g, edgetype(g)(src, dst))

function rem_edge!(graph::AbstractNamedGraph, edge)
  rem_edge!(parent_graph(graph), edge_to_parent_edge(graph, edge))
  return graph
end

function has_edge(graph::AbstractNamedGraph, edge::AbstractNamedEdge)
  return has_edge(parent_graph(graph), edge_to_parent_edge(graph, edge))
end

# handles two-argument edge constructors like src,dst
has_edge(g::AbstractNamedGraph, edge) = has_edge(g, edgetype(g)(edge))
has_edge(g::AbstractNamedGraph, src, dst) = has_edge(g, edgetype(g)(src, dst))

function has_path(graph::AbstractNamedGraph, source, destination; exclude_vertices=vertextype(graph)[])
  return has_path(
    parent_graph(graph),
    vertex_to_parent_vertex(graph, source),
    vertex_to_parent_vertex(graph, destination);
    exclude_vertices=vertices_to_parent_vertices(graph, exclude_vertices),
  )
end

function union(graph1::AbstractNamedGraph, graph2::AbstractNamedGraph)
  union_graph = promote_type(typeof(graph1), typeof(graph2))()
  union_vertices = union(vertices(graph1), vertices(graph2))
  for v in union_vertices
    add_vertex!(union_graph, v)
  end
  for e in edges(graph1)
    add_edge!(union_graph, e)
  end
  for e in edges(graph2)
    add_edge!(union_graph, e)
  end
  return union_graph
end

function add_vertex!(graph::AbstractNamedGraph, vertex)
  if vertex ∈ vertices(graph)
    throw(ArgumentError("Duplicate vertices are not allowed"))
  end
  add_vertex!(parent_graph(graph))
  # Update the vertex list
  push!(vertices(graph), vertex)
  # Update the reverse map
  # TODO: Make this more generic
  insert!(graph.vertex_to_parent_vertex, vertex, last(parent_vertices(graph)))
  return graph
end

function rem_vertex!(graph::AbstractNamedGraph, vertex)
  parent_vertex = vertex_to_parent_vertex(graph, vertex)
  rem_vertex!(parent_graph(graph), parent_vertex)

  # Insert the last vertex into the position of the vertex
  # that is being deleted, then remove the last vertex.
  last_vertex = last(vertices(graph))
  vertices(graph)[parent_vertex] = last_vertex
  last_vertex = pop!(vertices(graph))

  # Insert the last vertex into the position of the vertex
  # that is being deleted, then remove the last vertex.
  # TODO: Make this more generic
  graph.vertex_to_parent_vertex[last_vertex] = parent_vertex
  # TODO: Make this more generic
  delete!(graph.vertex_to_parent_vertex, vertex)

  return graph
end

function add_vertices!(graph::AbstractNamedGraph, vs::Vector)
  for vertex in vs
    add_vertex!(graph, vertex)
  end
  return graph
end

is_directed(G::Type{<:AbstractNamedGraph}) = is_directed(parent_graph_type(G))

is_directed(graph::AbstractNamedGraph) = is_directed(parent_graph(graph))

is_connected(graph::AbstractNamedGraph) = is_connected(parent_graph(graph))

is_cyclic(graph::AbstractNamedGraph) = is_cyclic(parent_graph(graph))

@traitfn function reverse(graph::AbstractNamedGraph::IsDirected)
  reversed_parent_graph = reverse(parent_graph(graph))
  return h
end

@traitfn function reverse!(g::AbstractNamedGraph::IsDirected)
  g.fadjlist, g.badjlist = g.badjlist, g.fadjlist
  return g
end

# TODO: Move to namedgraph.jl, or make the output generic?
function blockdiag(graph1::AbstractNamedGraph, graph2::AbstractNamedGraph)
  new_parent_graph = blockdiag(parent_graph(graph1), parent_graph(graph2))
  new_vertices = vcat(vertices(graph1), vertices(graph2))
  @assert allunique(new_vertices)
  return GenericNamedGraph(new_parent_graph, new_vertices)
end

# TODO: What `args` are needed?
nv(graph::AbstractNamedGraph, args...) = nv(parent_graph(graph), args...)
# TODO: What `args` are needed?
ne(graph::AbstractNamedGraph, args...) = ne(parent_graph(graph), args...)
# TODO: What `args` are needed?
function adjacency_matrix(graph::AbstractNamedGraph, args...)
  return adjacency_matrix(parent_graph(graph), args...)
end

function connected_components(graph::AbstractNamedGraph)
  parent_connected_components = connected_components(parent_graph(graph))
  return map(parent_vertices_to_vertices(graph), parent_connected_components)
end

function merge_vertices!(graph::AbstractNamedGraph, merge_vertices; merged_vertex=first(merge_vertices))
  not_implemented()
end

function merge_vertices(graph::AbstractNamedGraph, merge_vertices; merged_vertex=first(merge_vertices))
  merged_graph = copy(graph)
  if !has_vertex(graph, merged_vertex)
    add_vertex!(merged_graph, merged_vertex)
  end
  for vertex in merge_vertices
    for e in incident_edges(graph, vertex; dir=:both)
      merged_edge = rename_vertices(v -> v == vertex ? merged_vertex : v, e)
      if src(merged_edge) ≠ dst(merged_edge)
        add_edge!(merged_graph, merged_edge)
      end
    end
  end
  for vertex in merge_vertices
    if vertex ≠ merged_vertex
      rem_vertex!(merged_graph, vertex)
    end
  end
  return merged_graph
end

# 
# Graph traversals
#

# Overload Graphs.tree. Used for bfs_tree and dfs_tree
# traversal algorithms.
function tree(graph::AbstractNamedGraph, parents)
  n = length(parents)
  # TODO: Use `directed_graph` here to make more generic?
  ## t = GenericNamedGraph(DiGraph(n), vertices(graph))
  t = directed_graph(typeof(graph))(vertices(graph))
  for destination in eachindex(parents)
    source = parents[destination]
    if source != destination
      add_edge!(t, source, destination)
    end
  end
  return t
end

_bfs_tree(graph::AbstractNamedGraph, vertex; kwargs...) = tree(graph, bfs_parents(graph, vertex; kwargs...))
# Disambiguation from Graphs.bfs_tree
bfs_tree(graph::AbstractNamedGraph, vertex::Integer; kwargs...) = _bfs_tree(graph, vertex; kwargs...)
bfs_tree(graph::AbstractNamedGraph, vertex; kwargs...) = _bfs_tree(graph, vertex; kwargs...)

# Returns a Dictionary mapping a vertex to it's parent
# vertex in the traversal/spanning tree.
function _bfs_parents(graph::AbstractNamedGraph, vertex; kwargs...)
  parent_bfs_parents = bfs_parents(
    parent_graph(graph), vertex_to_parent_vertex(graph, vertex); kwargs...
  )
  return Dictionary(vertices(graph), parent_vertices_to_vertices(graph, parent_bfs_parents))
end
# Disambiguation from Graphs.bfs_tree
bfs_parents(graph::AbstractNamedGraph, vertex::Integer; kwargs...) = _bfs_parents(graph, vertex; kwargs...)
bfs_parents(graph::AbstractNamedGraph, vertex; kwargs...) = _bfs_parents(graph, vertex; kwargs...)

_dfs_tree(graph::AbstractNamedGraph, vertex; kwargs...) = tree(graph, dfs_parents(graph, vertex; kwargs...))
dfs_tree(graph::AbstractNamedGraph, vertex::Integer; kwargs...) = _dfs_tree(graph, vertex; kwargs...)
dfs_tree(graph::AbstractNamedGraph, vertex; kwargs...) = _dfs_tree(graph, vertex; kwargs...)

# Returns a Dictionary mapping a vertex to it's parent
# vertex in the traversal/spanning tree.
function _dfs_parents(graph::AbstractNamedGraph, vertex; kwargs...)
  parent_dfs_parents = dfs_parents(
    parent_graph(graph), vertex_to_parent_vertex(graph, vertex); kwargs...
  )
  return Dictionary(vertices(graph), parent_vertices_to_vertices(graph, parent_dfs_parents))
end
# Disambiguation from Graphs.dfs_tree
dfs_parents(graph::AbstractNamedGraph, vertex::Integer; kwargs...) = _dfs_parents(graph, vertex; kwargs...)
dfs_parents(graph::AbstractNamedGraph, vertex; kwargs...) = _dfs_parents(graph, vertex; kwargs...)

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

# 
# Convenience functions
#

function (g1::AbstractNamedGraph == g2::AbstractNamedGraph)
  issetequal(vertices(g1), vertices(g2)) || return false
  for v in vertices(g1)
    issetequal(inneighbors(g1, v), inneighbors(g2, v)) || return false
    issetequal(outneighbors(g1, v), outneighbors(g2, v)) || return false
  end
  return true
end
