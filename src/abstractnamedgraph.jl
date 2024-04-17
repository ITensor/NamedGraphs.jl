using Dictionaries: set!
using Graphs:
  Graphs,
  AbstractGraph,
  IsDirected,
  a_star,
  add_edge!,
  adjacency_matrix,
  bfs_parents,
  boruvka_mst,
  connected_components,
  degree,
  edges,
  has_path,
  indegree,
  inneighbors,
  is_connected,
  is_cyclic,
  kruskal_mst,
  ne,
  neighborhood,
  neighborhood_dists,
  nv,
  outdegree,
  prim_mst,
  rem_edge!,
  spfa_shortest_paths,
  vertices,
  weights
using Graphs.SimpleGraphs: SimpleDiGraph, SimpleEdge
using .GraphsExtensions:
  GraphsExtensions,
  directed_graph,
  incident_edges,
  partitioned_vertices,
  rename_vertices,
  subgraph
using SimpleTraits: SimpleTraits, Not, @traitfn

abstract type AbstractNamedGraph{V} <: AbstractGraph{V} end

#
# Required for interface
#

Graphs.vertices(graph::AbstractNamedGraph) = not_implemented()
parent_graph(graph::AbstractNamedGraph) = not_implemented()

# TODO: Require this for the interface, or implement as:
# typeof(parent_graph(graph))
# ?
parent_graph_type(graph::AbstractNamedGraph) = not_implemented()

Graphs.rem_vertex!(graph::AbstractNamedGraph, vertex) = not_implemented()
Graphs.add_vertex!(graph::AbstractNamedGraph, vertex) = not_implemented()

GraphsExtensions.rename_vertices(f::Function, g::AbstractNamedGraph) = not_implemented()

function GraphsExtensions.permute_vertices(graph::AbstractNamedGraph, permutation)
  return subgraph(graph, parent_vertices_to_vertices(graph, permutation))
end

# Convert vertex to parent vertex
# Inverse map of `parent_vertex_to_vertex`.
vertex_to_parent_vertex(graph::AbstractNamedGraph, vertex) = not_implemented()

# Convert parent vertex to vertex.
# Use `vertices`, assumes `vertices` is indexed by a parent vertex (a Vector for linear indexed parent vertices, a dictionary in general).
parent_vertex_to_vertex(graph::AbstractNamedGraph, parent_vertex) = not_implemented()

Graphs.edgetype(graph::AbstractNamedGraph) = not_implemented()

# TODO: Define generic version in `GraphsExtensions`.
GraphsExtensions.directed_graph_type(G::Type{<:AbstractNamedGraph}) = not_implemented()
GraphsExtensions.undirected_graph_type(G::Type{<:AbstractNamedGraph}) = not_implemented()

# In terms of `parent_graph_type`
# is_directed(::Type{<:AbstractNamedGraph}) = not_implemented()

GraphsExtensions.convert_vertextype(::Type, ::AbstractNamedGraph) = not_implemented()

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
Base.copy(graph::AbstractNamedGraph) = not_implemented()

function Graphs.merge_vertices!(
  graph::AbstractNamedGraph, merge_vertices; merged_vertex=first(merge_vertices)
)
  return not_implemented()
end

#
# Derived interface
#

function Graphs.has_vertex(graph::AbstractNamedGraph, vertex)
  return vertex ∈ vertices(graph)
end

parent_vertextype(graph::AbstractNamedGraph) = vertextype(parent_graph(graph))

Graphs.SimpleDiGraph(graph::AbstractNamedGraph) = SimpleDiGraph(parent_graph(graph))

# Convenient shorthands for using in higher order functions like `map`.
function vertex_to_parent_vertex(graph::AbstractNamedGraph)
  return Base.Fix1(vertex_to_parent_vertex, graph)
end
function parent_vertex_to_vertex(graph::AbstractNamedGraph)
  return Base.Fix1(parent_vertex_to_vertex, graph)
end

Base.zero(G::Type{<:AbstractNamedGraph}) = G()

# TODO: Implement using `copyto!`?
function GraphsExtensions.directed_graph(graph::AbstractNamedGraph)
  digraph = directed_graph_type(typeof(graph))(vertices(graph))
  for e in edges(graph)
    add_edge!(digraph, e)
    add_edge!(digraph, reverse(e))
  end
  return digraph
end

# Default, can overload
Base.eltype(graph::AbstractNamedGraph) = eltype(vertices(graph))

parent_eltype(graph::AbstractNamedGraph) = eltype(parent_graph(graph))

function vertices_to_parent_vertices(graph::AbstractNamedGraph, vertices)
  return map(vertex_to_parent_vertex(graph), vertices)
end

function vertices_to_parent_vertices(graph::AbstractNamedGraph)
  return Base.Fix1(vertices_to_parent_vertices, graph)
end

function parent_vertices_to_vertices(graph::AbstractNamedGraph, parent_vertices)
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

function Graphs.edges(graph::AbstractNamedGraph)
  return parent_edges_to_edges(graph, parent_edges(graph))
end

# TODO: write in terms of a generic function.
for f in [
  :(Graphs.outneighbors),
  :(Graphs.inneighbors),
  :(Graphs.all_neighbors),
  :(Graphs.neighbors),
]
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

function Graphs.common_neighbors(g::AbstractNamedGraph, u, v)
  return intersect(neighbors(g, u), neighbors(g, v))
end

namedgraph_indegree(graph::AbstractNamedGraph, vertex) = length(inneighbors(graph, vertex))
function namedgraph_outdegree(graph::AbstractNamedGraph, vertex)
  return length(outneighbors(graph, vertex))
end

Graphs.indegree(graph::AbstractNamedGraph, vertex) = namedgraph_indegree(graph, vertex)
Graphs.outdegree(graph::AbstractNamedGraph, vertex) = namedgraph_outdegree(graph, vertex)

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.indegree(graph::AbstractNamedGraph, vertex::Integer)
  return namedgraph_indegree(graph, vertex)
end
function Graphs.outdegree(graph::AbstractNamedGraph, vertex::Integer)
  return namedgraph_outdegree(graph, vertex)
end

@traitfn function namedgraph_degree(graph::AbstractNamedGraph::IsDirected, vertex)
  return indegree(graph, vertex) + outdegree(graph, vertex)
end
@traitfn namedgraph_degree(graph::AbstractNamedGraph::(!IsDirected), vertex) =
  indegree(graph, vertex)

function Graphs.degree(graph::AbstractNamedGraph, vertex)
  return namedgraph_degree(graph::AbstractNamedGraph, vertex)
end

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.degree(graph::AbstractNamedGraph, vertex::Integer)
  return namedgraph_degree(graph::AbstractNamedGraph, vertex)
end

function Graphs.degree_histogram(g::AbstractNamedGraph, degfn=degree)
  hist = Dictionary{Int,Int}()
  for v in vertices(g)        # minimize allocations by
    for d in degfn(g, v)    # iterating over vertices
      set!(hist, d, get(hist, d, 0) + 1)
    end
  end
  return hist
end

function namedgraph_neighborhood(
  graph::AbstractNamedGraph, vertex, d, distmx=weights(graph); dir=:out
)
  parent_distmx = dist_matrix_to_parent_dist_matrix(graph, distmx)
  parent_vertices = neighborhood(
    parent_graph(graph), vertex_to_parent_vertex(graph, vertex), d, parent_distmx; dir
  )
  return [
    parent_vertex_to_vertex(graph, parent_vertex) for parent_vertex in parent_vertices
  ]
end

function Graphs.neighborhood(
  graph::AbstractNamedGraph, vertex, d, distmx=weights(graph); dir=:out
)
  return namedgraph_neighborhood(graph, vertex, d, distmx; dir)
end

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.neighborhood(
  graph::AbstractNamedGraph, vertex::Integer, d, distmx=weights(graph); dir=:out
)
  return namedgraph_neighborhood(graph, vertex, d, distmx; dir)
end

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.neighborhood(
  graph::AbstractNamedGraph, vertex::Integer, d, distmx::AbstractMatrix{<:Real}; dir=:out
)
  return namedgraph_neighborhood(graph, vertex, d, distmx; dir)
end

function namedgraph_neighborhood_dists(graph::AbstractNamedGraph, vertex, d, distmx; dir)
  parent_distmx = dist_matrix_to_parent_dist_matrix(graph, distmx)
  parent_vertices_and_dists = neighborhood_dists(
    parent_graph(graph), vertex_to_parent_vertex(graph, vertex), d, parent_distmx; dir
  )
  return [
    (parent_vertex_to_vertex(graph, parent_vertex), dist) for
    (parent_vertex, dist) in parent_vertices_and_dists
  ]
end

function Graphs.neighborhood_dists(
  graph::AbstractNamedGraph, vertex, d, distmx=weights(graph); dir=:out
)
  return namedgraph_neighborhood_dists(graph, vertex, d, distmx; dir)
end

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.neighborhood_dists(
  graph::AbstractNamedGraph, vertex::Integer, d, distmx=weights(graph); dir=:out
)
  return namedgraph_neighborhood_dists(graph, vertex, d, distmx; dir)
end

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.neighborhood_dists(
  graph::AbstractNamedGraph, vertex::Integer, d, distmx::AbstractMatrix{<:Real}; dir=:out
)
  return namedgraph_neighborhood_dists(graph, vertex, d, distmx; dir)
end

function namedgraph_mincut(graph::AbstractNamedGraph, distmx)
  parent_distmx = dist_matrix_to_parent_dist_matrix(graph, distmx)
  parent_parity, bestcut = Graphs.mincut(parent_graph(graph), parent_distmx)
  return Dictionary(vertices(graph), parent_parity), bestcut
end

function Graphs.mincut(graph::AbstractNamedGraph, distmx=weights(graph))
  return namedgraph_mincut(graph, distmx)
end

function Graphs.mincut(graph::AbstractNamedGraph, distmx::AbstractMatrix{<:Real})
  return namedgraph_mincut(graph, distmx)
end

# TODO: Make this more generic?
function GraphsExtensions.partitioned_vertices(
  g::AbstractNamedGraph; npartitions=nothing, nvertices_per_partition=nothing, kwargs...
)
  vertex_partitions = partitioned_vertices(
    parent_graph(g); npartitions, nvertices_per_partition, kwargs...
  )
  #[inv(vertex_to_parent_vertex(g))[v] for v in partitions]
  # TODO: output the reverse of this dictionary (a Vector of Vector
  # of the vertices in each partition).
  # return Dictionary(vertices(g), partitions)
  return [
    parent_vertices_to_vertices(g, vertex_partition) for
    vertex_partition in vertex_partitions
  ]
end

function namedgraph_a_star(
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

function Graphs.a_star(graph::AbstractNamedGraph, source, destination, args...)
  return namedgraph_a_star(graph, source, destination, args...)
end

# Fix ambiguity error with `AbstractGraph` version
function Graphs.a_star(
  graph::AbstractNamedGraph{U}, source::Integer, destination::Integer, args...
) where {U<:Integer}
  return namedgraph_a_star(graph, source, destination, args...)
end

function Graphs.spfa_shortest_paths(
  graph::AbstractNamedGraph, vertex, distmx=weights(graph)
)
  parent_distmx = dist_matrix_to_parent_dist_matrix(graph, distmx)
  parent_shortest_paths = spfa_shortest_paths(
    parent_graph(graph), vertex_to_parent_vertex(graph, vertex), parent_distmx
  )
  return Dictionary(vertices(graph), parent_shortest_paths)
end

function Graphs.boruvka_mst(
  g::AbstractNamedGraph, distmx::AbstractMatrix{<:Real}=weights(g); minimize=true
)
  parent_mst, weights = boruvka_mst(parent_graph(g), distmx; minimize)
  return parent_edges_to_edges(g, parent_mst), weights
end

function Graphs.kruskal_mst(
  g::AbstractNamedGraph, distmx::AbstractMatrix{<:Real}=weights(g); minimize=true
)
  parent_mst = kruskal_mst(parent_graph(g), distmx; minimize)
  return parent_edges_to_edges(g, parent_mst)
end

function Graphs.prim_mst(g::AbstractNamedGraph, distmx::AbstractMatrix{<:Real}=weights(g))
  parent_mst = prim_mst(parent_graph(g), distmx)
  return parent_edges_to_edges(g, parent_mst)
end

function Graphs.add_edge!(graph::AbstractNamedGraph, edge::AbstractEdge)
  add_edge!(parent_graph(graph), edge_to_parent_edge(graph, edge))
  return graph
end

# handles single-argument edge constructors such as pairs and tuples
Graphs.add_edge!(g::AbstractNamedGraph, edge) = add_edge!(g, edgetype(g)(edge))
Graphs.add_edge!(g::AbstractNamedGraph, src, dst) = add_edge!(g, edgetype(g)(src, dst))

function Graphs.rem_edge!(graph::AbstractNamedGraph, edge)
  rem_edge!(parent_graph(graph), edge_to_parent_edge(graph, edge))
  return graph
end

function Graphs.has_edge(graph::AbstractNamedGraph, edge::AbstractNamedEdge)
  return has_edge(parent_graph(graph), edge_to_parent_edge(graph, edge))
end

# handles two-argument edge constructors like src,dst
Graphs.has_edge(g::AbstractNamedGraph, edge) = has_edge(g, edgetype(g)(edge))
Graphs.has_edge(g::AbstractNamedGraph, src, dst) = has_edge(g, edgetype(g)(src, dst))

function Graphs.has_path(
  graph::AbstractNamedGraph, source, destination; exclude_vertices=vertextype(graph)[]
)
  return has_path(
    parent_graph(graph),
    vertex_to_parent_vertex(graph, source),
    vertex_to_parent_vertex(graph, destination);
    exclude_vertices=vertices_to_parent_vertices(graph, exclude_vertices),
  )
end

function Base.union(graph1::AbstractNamedGraph, graph2::AbstractNamedGraph)
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

function Base.union(
  graph1::AbstractNamedGraph,
  graph2::AbstractNamedGraph,
  graph3::AbstractNamedGraph,
  graph_rest::AbstractNamedGraph...,
)
  return union(union(graph1, graph2), graph3, graph_rest...)
end

Graphs.is_directed(G::Type{<:AbstractNamedGraph}) = is_directed(parent_graph_type(G))

Graphs.is_directed(graph::AbstractNamedGraph) = is_directed(parent_graph(graph))

Graphs.is_connected(graph::AbstractNamedGraph) = is_connected(parent_graph(graph))

Graphs.is_cyclic(graph::AbstractNamedGraph) = is_cyclic(parent_graph(graph))

@traitfn function Base.reverse(graph::AbstractNamedGraph::IsDirected)
  reversed_parent_graph = reverse(parent_graph(graph))
  return h
end

@traitfn function Base.reverse!(g::AbstractNamedGraph::IsDirected)
  g.fadjlist, g.badjlist = g.badjlist, g.fadjlist
  return g
end

# TODO: Move to `namedgraph.jl`, or make the output generic?
function Graphs.blockdiag(graph1::AbstractNamedGraph, graph2::AbstractNamedGraph)
  new_parent_graph = blockdiag(parent_graph(graph1), parent_graph(graph2))
  new_vertices = vcat(vertices(graph1), vertices(graph2))
  @assert allunique(new_vertices)
  return GenericNamedGraph(new_parent_graph, new_vertices)
end

# TODO: What `args` are needed?
Graphs.nv(graph::AbstractNamedGraph, args...) = nv(parent_graph(graph), args...)
# TODO: What `args` are needed?
Graphs.ne(graph::AbstractNamedGraph, args...) = ne(parent_graph(graph), args...)
# TODO: What `args` are needed?
function Graphs.adjacency_matrix(graph::AbstractNamedGraph, args...)
  return adjacency_matrix(parent_graph(graph), args...)
end

function Graphs.connected_components(graph::AbstractNamedGraph)
  parent_connected_components = connected_components(parent_graph(graph))
  return map(parent_vertices_to_vertices(graph), parent_connected_components)
end

function Graphs.merge_vertices(
  graph::AbstractNamedGraph, merge_vertices; merged_vertex=first(merge_vertices)
)
  merged_graph = copy(graph)
  add_vertex!(merged_graph, merged_vertex)
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
function Graphs.tree(graph::AbstractNamedGraph, parents)
  n = length(parents)
  # TODO: Use `directed_graph` here to make more generic?
  ## t = GenericNamedGraph(DiGraph(n), vertices(graph))
  t = directed_graph_type(typeof(graph))(vertices(graph))
  for destination in eachindex(parents)
    source = parents[destination]
    if source != destination
      add_edge!(t, source, destination)
    end
  end
  return t
end

function namedgraph_bfs_tree(graph::AbstractNamedGraph, vertex; kwargs...)
  return Graphs.tree(graph, bfs_parents(graph, vertex; kwargs...))
end
# Disambiguation from Graphs.bfs_tree
function Graphs.bfs_tree(graph::AbstractNamedGraph, vertex::Integer; kwargs...)
  return namedgraph_bfs_tree(graph, vertex; kwargs...)
end
function Graphs.bfs_tree(graph::AbstractNamedGraph, vertex; kwargs...)
  return namedgraph_bfs_tree(graph, vertex; kwargs...)
end

# Returns a Dictionary mapping a vertex to it's parent
# vertex in the traversal/spanning tree.
function namedgraph_bfs_parents(graph::AbstractNamedGraph, vertex; kwargs...)
  parent_bfs_parents = bfs_parents(
    parent_graph(graph), vertex_to_parent_vertex(graph, vertex); kwargs...
  )
  # Works around issue in this `Dictionary` constructor:
  # https://github.com/andyferris/Dictionaries.jl/blob/v0.4.1/src/Dictionary.jl#L139-L145
  # when `inds` has holes. This removes the holes.
  # TODO: Raise an issue with `Dictionaries.jl`.
  ## vertices_graph = Indices(collect(vertices(graph)))
  # This makes the vertices ordered according to the parent vertices.
  vertices_graph = parent_vertices_to_vertices(graph, parent_vertices(graph))
  return Dictionary(vertices_graph, parent_vertices_to_vertices(graph, parent_bfs_parents))
end
# Disambiguation from Graphs.jl
function Graphs.bfs_parents(graph::AbstractNamedGraph, vertex::Integer; kwargs...)
  return namedgraph_bfs_parents(graph, vertex; kwargs...)
end
function Graphs.bfs_parents(graph::AbstractNamedGraph, vertex; kwargs...)
  return namedgraph_bfs_parents(graph, vertex; kwargs...)
end

#
# Printing
#

function Base.show(io::IO, mime::MIME"text/plain", graph::AbstractNamedGraph)
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

Base.show(io::IO, graph::AbstractNamedGraph) = show(io, MIME"text/plain"(), graph)

# 
# Convenience functions
#

function Base.:(==)(g1::AbstractNamedGraph, g2::AbstractNamedGraph)
  issetequal(vertices(g1), vertices(g2)) || return false
  for v in vertices(g1)
    issetequal(inneighbors(g1, v), inneighbors(g2, v)) || return false
    issetequal(outneighbors(g1, v), outneighbors(g2, v)) || return false
  end
  return true
end
