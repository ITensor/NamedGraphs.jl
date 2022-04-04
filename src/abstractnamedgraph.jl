abstract type AbstractNamedGraph{V} <: AbstractGraph{V} end

#
# Required for interface
#

vertices(graph::AbstractNamedGraph) = not_implemented()
parent_graph(graph::AbstractNamedGraph) = not_implemented()
vertex_to_parent_vertex(graph::AbstractNamedGraph, vertex...) = not_implemented()

# Convert parent vertex to vertex.
# Use `vertices`, assumes `vertices` is indexed by a parent vertex (a Vector for linear indexed parent vertices, a dictionary in general).
parent_vertex_to_vertex(graph::AbstractNamedGraph, parent_vertex) = vertices(graph)[parent_vertex]

# Convert a collection of vertices to a collection of parent vertices.
# This should be overloaded for multi-dimensional indexing.
function vertices_to_parent_vertices(graph::AbstractNamedGraph{V}, vertices::Vector{V}) where {V}
  return [vertex_to_parent_vertex(graph, vertex) for vertex in vertices]
end

# This can be customized.
edgetype(graph::AbstractNamedGraph{V}) where {V} = NamedEdge{V}

eltype(g::AbstractNamedGraph{V}) where {V} = V

parent_vertices(graph::AbstractNamedGraph) = vertices(parent_graph(graph))
parent_edges(graph::AbstractNamedGraph) = edges(parent_graph(graph))
parent_edgetype(graph::AbstractNamedGraph) = edgetype(parent_graph(graph))

function edge_to_parent_edge(graph::AbstractNamedGraph, edge)
  parent_src = vertex_to_parent_vertex(graph, src(edge))
  parent_dst = vertex_to_parent_vertex(graph, dst(edge))
  return parent_edgetype(graph)(parent_src, parent_dst)
end

# TODO: This is `O(nv(g))`, use `haskey(vertex_to_parent_vertex(g), v)` instead?
has_vertex(g::AbstractNamedGraph, v) = v in vertices(g)

function edges(graph::AbstractNamedGraph)
  vertex(parent_vertex) = vertices(graph)[parent_vertex]
  edge(parent_edge) = NamedEdge(vertex(src(parent_edge)), vertex(dst(parent_edge)))
  return map(edge, parent_edges(graph))
end

# TODO: write in terms of a generic function.
for f in [:outneighbors, :inneighbors, :all_neighbors, :neighbors]
  @eval begin
    function $f(graph::AbstractNamedGraph, v)
      parent_vertices = $f(parent_graph(graph), vertex_to_parent_vertex(graph, v))
      return [parent_vertex_to_vertex(graph, u) for u ∈ parent_vertices]
    end
  end
end

# Ambiguity errors with Graphs.jl
neighbors(tn::AbstractNamedGraph, vertex::Integer) = neighbors(parent_graph(tn), vertex)
inneighbors(tn::AbstractNamedGraph, vertex::Integer) = inneighbors(parent_graph(tn), vertex)
outneighbors(tn::AbstractNamedGraph, vertex::Integer) = outneighbors(parent_graph(tn), vertex)
all_neighbors(tn::AbstractNamedGraph, vertex::Integer) = all_neighbors(parent_graph(tn), vertex)

function add_edge!(graph::AbstractNamedGraph, edge::NamedEdge)
  add_edge!(parent_graph(graph), edge_to_parent_edge(graph, edge))
  return graph
end

function has_edge(graph::AbstractNamedGraph, edge::NamedEdge)
  return has_edge(parent_graph(graph), edge_to_parent_edge(graph, edge))
end

# handles single-argument edge constructors such as pairs and tuples
has_edge(g::AbstractNamedGraph, x) = has_edge(g, edgetype(g)(x))
add_edge!(g::AbstractNamedGraph, x) = add_edge!(g, edgetype(g)(x))

# handles two-argument edge constructors like src,dst
has_edge(g::AbstractNamedGraph, x, y) = has_edge(g, edgetype(g)(x, y))
add_edge!(g::AbstractNamedGraph, x, y) = add_edge!(g, edgetype(g)(x, y))

function add_vertex!(graph::AbstractNamedGraph, v)
  if v ∈ vertices(graph)
    throw(ArgumentError("Duplicate vertices are not allowed"))
  end
  add_vertex!(parent_graph(graph))
  insert!(vertex_to_parent_vertex(graph), v, last(parent_vertices(graph)))
  return graph
end

function add_vertices!(graph::AbstractNamedGraph, vertices::Vector)
  if any(v ∈ vertices(graph) for v ∈ vertices)
    throw(ArgumentError("Duplicate vertices are not allowed"))
  end
  for vertex in vertices
    add_vertex!(graph, vertex)
  end
  return graph
end

function getindex(graph::AbstractNamedGraph, vertices...)
  parent_graph_vertices = vertices_to_parent_vertices(graph, vertices...)
  parent_sub_graph, _ = induced_subgraph(parent_graph(graph), parent_graph_vertices)
  return typeof(graph)(parent_sub_graph, vertices...)
end

is_directed(LG::Type{<:AbstractNamedGraph}) = is_directed(parent_graph_type(LG))

# Rename `disjoint_union`: https://networkx.org/documentation/stable/reference/algorithms/operators.html
function blockdiag(graph1::AbstractNamedGraph, graph2::AbstractNamedGraph)
  new_parent_graph = blockdiag(parent_graph(graph1), parent_graph(graph2))
  new_vertices = vcat(vertices(graph1), vertices(graph2))
  return AbstractNamedGraph(new_parent_graph, new_vertices)
end

nv(graph::AbstractNamedGraph, args...) = nv(parent_graph(graph), args...)
ne(graph::AbstractNamedGraph, args...) = ne(parent_graph(graph), args...)
adjacency_matrix(graph::AbstractNamedGraph, args...) = adjacency_matrix(parent_graph(graph), args...)

function show(io::IO, mime::MIME"text/plain", graph::AbstractNamedGraph)
  println(io, "AbstractNamedGraph with $(nv(graph)) vertices:")
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

# XXX: Maybe required?
# Define through things like `similar`, `add_edge!`, etc.
# AbstractNamedGraph(copy(parent_graph(graph)), copy(vertex_to_parent_vertex(graph)))
# copy(graph::AbstractNamedGraph) = not_implemented()

# XXX: Deprecated.
# vertex_to_parent_vertex(graph::AbstractNamedGraph) = error("DEPRECATED")
# parent_vertex_to_vertex(graph::AbstractNamedGraph) = error("DEPRECATED")

# XXX: Deprecated. Use `vertex_to_parent_vertex`.
#parent_vertex(graph::AbstractNamedGraph, vertex) = vertex_to_parent_vertex(graph, vertex)

# XXX: Deprecated. Use `vertex_to_parent_vertex`.
#parent_vertices(graph::AbstractNamedGraph, vertices) = [parent_vertex(graph, vertex) for vertex in vertices]

#AbstractNamedGraph(vertices::Vector{T}) where T = AbstractNamedGraph{Graph{Int}}(vertices)
#NamedDiGraph(vertices::Vector{T}) where T = AbstractNamedGraph{DiGraph{Int}}(vertices)

# XXX: Deprecated.
# AbstractNamedGraph(graph, vertices)
#set_vertices(graph::AbstractGraph, vertices) = not_implemented()

# XXX: Don't assume type information.
# typeof(parent_graph(graph))
#parent_graph_type(::Type{<:AbstractNamedGraph{<:Any,G}}) where {G} = G

## function AbstractNamedGraph(graph::AbstractGraph, vertices=default_vertices(graph))
##   if length(vertices) != nv(graph)
##     throw(ArgumentError("Vertices and parent graph's vertices must have equal length."))
##   end
##   if !allunique(vertices)
##     throw(ArgumentError("Vertices have to be unique."))
##   end

##   vs = map(v -> CartesianKey(v), vertices)
##   return AbstractNamedGraph(graph, bijection(MultiDimDictionary, Dictionary, vs, 1:length(vs)))
## end

## function AbstractNamedGraph(graph::AbstractGraph, dims::Tuple{Vararg{Integer}})
##   return AbstractNamedGraph(graph, vec(Tuple.(CartesianIndices(dims))))
## end

## function AbstractNamedGraph(dims::Tuple{Vararg{Integer}})
##   return AbstractNamedGraph(Graph(prod(dims)), vec(Tuple.(CartesianIndices(dims))))
## end

## function AbstractNamedGraph{S}(vertices::Vector) where {S<:AbstractGraph}
##   return AbstractNamedGraph(S(length(vertices)), vertices)
## end
