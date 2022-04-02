module NamedGraphs
  using AbstractBijections
  using Dictionaries
  using MultiDimDictionaries
  using Graphs

  export set_vertices

  import Graphs: src, dst, nv, vertices, has_vertex, ne, edges, has_edge, neighbors, outneighbors, inneighbors, all_neighbors, is_directed, add_edge!, add_vertex!, add_vertices!, induced_subgraph, adjacency_matrix, blockdiag, edgetype

  import Base: show, eltype, copy

  # TODO: restrict to `AbstractSimpleGraph` (graph with contiguous integer vertices)
  # and `InvVectorBijection`, a Bijection where the inverse is a `Vector` (maps a contiguous
  # space of integers to another space).
  # TODO: rename `parent_graph` to something more descriptive like `simple_graph`, `int_vertex_graph`, etc.
  struct NamedGraph{V,G<:AbstractGraph,B<:AbstractBijection} <: AbstractGraph{V}
    parent_graph::G
    vertex_to_parent_vertex::B # Invertible map from the vertices to the parent vertices
    function NamedGraph(parent_graph::G, vertex_to_parent_vertex::B) where {G<:AbstractGraph,B<:AbstractBijection}
      @assert issetequal(vertices(parent_graph), image(vertex_to_parent_vertex))
      V = domain_eltype(vertex_to_parent_vertex)
      return new{V,G,B}(parent_graph, vertex_to_parent_vertex)
    end
  end
  parent_graph(graph::NamedGraph) = graph.parent_graph
  vertex_to_parent_vertex(graph::NamedGraph) = graph.vertex_to_parent_vertex

  copy(graph::NamedGraph) = NamedGraph(copy(parent_graph(graph)), copy(vertex_to_parent_vertex(graph)))

  eltype(g::NamedGraph{V}) where {V} = V

  # Convenient constructor
  set_vertices(graph::AbstractGraph, vertices) = NamedGraph(graph, vertices)

  vertices(graph::NamedGraph) = domain(vertex_to_parent_vertex(graph))

  parent_graph_type(::Type{<:NamedGraph{<:Any,G}}) where {G} = G

  parent_vertices(graph::NamedGraph) = vertices(parent_graph(graph))
  parent_edges(graph::NamedGraph) = edges(parent_graph(graph))
  parent_edgetype(graph::NamedGraph) = edgetype(parent_graph(graph))

  parent_vertex(graph::NamedGraph, vertex) = vertex_to_parent_vertex(graph)[vertex]
  parent_edge(graph::NamedGraph, edge) = parent_edgetype(graph)(parent_vertex(graph, src(edge)), parent_vertex(graph, dst(edge)))
  parent_vertices(graph::NamedGraph, vertices) = [parent_vertex(graph, vertex) for vertex in vertices]
  parent_vertex_to_vertex(graph::NamedGraph, parent_vertex) = vertices(graph)[parent_vertex]

  NamedGraph(vertices::Vector{T}) where T = NamedGraph{Graph{Int}}(vertices)
  NamedDiGraph(vertices::Vector{T}) where T = NamedGraph{DiGraph{Int}}(vertices)

  import Base: Pair, Tuple, show, ==, hash, eltype
  import Graphs: AbstractEdge, src, dst, reverse

  abstract type AbstractNamedEdge{V} <: AbstractEdge{V} end
  struct NamedEdge{V} <: AbstractNamedEdge{V}
    src::V
    dst::V
  end

  NamedEdge{T}(e::NamedEdge{T}) where {T} = e

  NamedEdge(t::Tuple) = NamedEdge(t[1], t[2])
  NamedEdge(p::Pair) = NamedEdge(p.first, p.second)
  NamedEdge{T}(p::Pair) where {T} = NamedEdge(T(p.first), T(p.second))
  NamedEdge{T}(t::Tuple) where {T} = NamedEdge(T(t[1]), T(t[2]))

  eltype(::Type{<:ET}) where ET<:AbstractNamedEdge{T} where T = T

  src(e::AbstractNamedEdge) = e.src
  dst(e::AbstractNamedEdge) = e.dst

  function show(io::IO, mime::MIME"text/plain", e::AbstractNamedEdge)
    show(io, src(e))
    print(io, " => ")
    show(io, dst(e))
    return nothing
  end

  show(io::IO, edge::AbstractNamedEdge) = show(io, MIME"text/plain"(), edge)

  # Conversions
  Pair(e::AbstractNamedEdge) = Pair(src(e), dst(e))
  Tuple(e::AbstractNamedEdge) = (src(e), dst(e))

  NamedEdge{T}(e::AbstractNamedEdge) where {T} = NamedEdge{T}(T(e.src), T(e.dst))

  # Convenience functions
  reverse(e::T) where T<:AbstractNamedEdge = T(dst(e), src(e))
  ==(e1::AbstractNamedEdge, e2::AbstractNamedEdge) = (src(e1) == src(e2) && dst(e1) == dst(e2))
  hash(e::AbstractNamedEdge, h::UInt) = hash(src(e), hash(dst(e), h))

  edgetype(graph::NamedGraph{V}) where {V} = NamedEdge{V}

  default_vertices(graph::AbstractGraph) = Vector(vertices(graph))

  function NamedGraph(graph::AbstractGraph, vertices=default_vertices(graph))
    if length(vertices) != nv(graph)
      throw(ArgumentError("Vertices and parent graph's vertices must have equal length."))
    end
    if !allunique(vertices)
      throw(ArgumentError("Vertices have to be unique."))
    end

    vs = map(v -> CartesianKey(v), vertices)
    return NamedGraph(graph, bijection(MultiDimDictionary, Dictionary, vs, 1:length(vs)))
  end

  function NamedGraph(graph::AbstractGraph, dims::Tuple{Vararg{Integer}})
    return NamedGraph(graph, vec(Tuple.(CartesianIndices(dims))))
  end

  function NamedGraph(dims::Tuple{Vararg{Integer}})
    return NamedGraph(Graph(prod(dims)), vec(Tuple.(CartesianIndices(dims))))
  end

  function NamedGraph{S}(vertices::Vector) where {S<:AbstractGraph}
    return NamedGraph(S(length(vertices)), vertices)
  end

  has_vertex(g::NamedGraph, v) = v in vertices(g)

  function edges(graph::NamedGraph)
    vertex(parent_vertex) = inv(vertex_to_parent_vertex(graph))[parent_vertex]
    edge(parent_edge) = NamedEdge(vertex(src(parent_edge)), vertex(dst(parent_edge)))
    return map(edge, parent_edges(graph))
  end

  for f in [:outneighbors, :inneighbors, :all_neighbors, :neighbors]
    @eval begin
      function $f(graph::NamedGraph, v)
        parent_vertices = $f(parent_graph(graph), parent_vertex(graph, v))
        return [parent_vertex_to_vertex(graph, u) for u ∈ parent_vertices]
      end
    end
  end

  # Ambiguity errors with Graphs.jl
  for f in [
    :neighbors, :inneighbors, :outneighbors, :all_neighbors
  ]
    @eval begin
      $f(tn::NamedGraph, vertex::Integer) = $f(parent_graph(tn), vertex)
    end
  end

  function add_edge!(graph::NamedGraph, edge::NamedEdge)
    add_edge!(parent_graph(graph), parent_edge(graph, edge))
    return graph
  end

  function has_edge(graph::NamedGraph, edge::NamedEdge)
    return has_edge(parent_graph(graph), parent_edge(graph, edge))
  end

  # handles single-argument edge constructors such as pairs and tuples
  has_edge(g::NamedGraph, x) = has_edge(g, edgetype(g)(x))
  add_edge!(g::NamedGraph, x) = add_edge!(g, edgetype(g)(x))

  # handles two-argument edge constructors like src,dst
  has_edge(g::NamedGraph, x, y) = has_edge(g, edgetype(g)(x, y))
  add_edge!(g::NamedGraph, x, y) = add_edge!(g, edgetype(g)(x, y))

  function add_vertex!(graph::NamedGraph, v)
    if v ∈ vertices(graph)
      throw(ArgumentError("Duplicate vertices are not allowed"))
    end
    add_vertex!(parent_graph(graph))
    insert!(vertex_to_parent_vertex(graph), v, last(parent_vertices(graph)))
    return graph
  end

  function add_vertices!(graph::NamedGraph, vertices::Vector)
    if any(v ∈ vertices(graph) for v ∈ vertices)
      throw(ArgumentError("Duplicate vertices are not allowed"))
    end
    for vertex in vertices
      add_vertex!(graph, vertex)
    end
    return graph
  end

  function induced_subgraph(graph::NamedGraph, sub_vertices::Vector)
    return _induced_subgraph(graph, _get_vertices(graph, sub_vertices))
  end

  function _get_vertices(graph::NamedGraph, vertex)
    return vertex
  end

  function _get_vertices(graph::NamedGraph, vertices::Vector)
    return mapreduce(vertex -> _get_vertices(graph, vertex), vcat, vertices)
  end

  function _induced_subgraph(graph::NamedGraph, vertices::Vector)
    sub_graph, _ = induced_subgraph(parent_graph(graph), parent_vertices(graph, vertices))
    return NamedGraph(sub_graph, vertices), vertices
  end

  is_directed(LG::Type{<:NamedGraph}) = is_directed(parent_graph_type(LG))

  # Rename `disjoint_union`: https://networkx.org/documentation/stable/reference/algorithms/operators.html
  function blockdiag(graph1::NamedGraph, graph2::NamedGraph)
    new_parent_graph = blockdiag(parent_graph(graph1), parent_graph(graph2))
    new_vertices = vcat(vertices(graph1), vertices(graph2))
    return NamedGraph(new_parent_graph, new_vertices)
  end

  for f in [:nv, :ne, :adjacency_matrix]
    @eval begin
      $f(graph::NamedGraph, args...) = $f(parent_graph(graph), args...)
    end
  end

  function show(io::IO, mime::MIME"text/plain", graph::NamedGraph)
    println(io, "NamedGraph with $(nv(graph)) vertices:")
    show(io, mime, vertices(graph))
    println(io, "\n")
    println(io, "and $(ne(graph)) edge(s):")
    for e in edges(graph)
      show(io, mime, e)
      println(io)
    end
    return nothing
  end

  show(io::IO, graph::NamedGraph) = show(io, MIME"text/plain"(), graph)
end # module NamedGraphs
