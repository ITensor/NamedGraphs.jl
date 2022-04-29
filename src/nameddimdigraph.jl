default_vertices(graph::DiGraph) = [tuple(v) for v in 1:nv(graph)]

struct NamedDimDiGraph{V<:Tuple} <: AbstractNamedGraph{V}
  parent_graph::SimpleDiGraph{Int}
  vertices::Vector{V}
  vertex_to_parent_vertex::MultiDimDictionary{V,Int}
end

is_directed(::Type{<:NamedDimDiGraph}) = true

function copy(graph::NamedDimDiGraph)
  return NamedDimDiGraph(
    copy(graph.parent_graph), copy(graph.vertices), copy(graph.vertex_to_parent_vertex)
  )
end

function NamedDimDiGraph{V}(
  parent_graph::DiGraph, vertices::Vector{V}=default_vertices(parent_graph)
) where {V<:Tuple}
  return NamedDimDiGraph{V}(
    parent_graph, vertices, MultiDimDictionary{V}(vertices, eachindex(vertices))
  )
end

function NamedDimDiGraph{V}(parent_graph::DiGraph, vertices::Vector) where {V<:Tuple}
  graph_vertices = tuple_convert.(vertices)
  return NamedDimDiGraph{V}(
    parent_graph,
    graph_vertices,
    MultiDimDictionary{Tuple}(graph_vertices, eachindex(graph_vertices)),
  )
end

function NamedDimDiGraph{V}(parent_graph::DiGraph, vertices) where {V<:Tuple}
  return NamedDimDiGraph{V}(parent_graph, collect(vertices))
end

function NamedDimDiGraph{V}(parent_graph::DiGraph, vertices::Array) where {V<:Tuple}
  return NamedDimDiGraph{V}(parent_graph, vec(vertices))
end

NamedDimDiGraph{V}() where {V} = NamedDimDiGraph{V}(DiGraph())

function NamedDimDiGraph(parent_graph::DiGraph, vertices::Array)
  # Could default to `eltype(vertices)`, but in general
  # we want the flexibility of `Tuple` for mixed key lengths
  # and types.
  return NamedDimDiGraph{Tuple}(parent_graph, vertices)
end

function NamedDimDiGraph(parent_graph::DiGraph, vertices)
  return NamedDimDiGraph(parent_graph, collect(vertices))
end

function NamedDimDiGraph(parent_graph::DiGraph; dims=nothing, vertices=nothing)
  if !isnothing(dims) && !isnothing(vertices)
    println("dims = ", dims)
    println("vertices = ", vertices)
    error("Must specify `dims` or `vertices` but not both.")
  elseif isnothing(dims) && isnothing(vertices)
    vertices = default_vertices(parent_graph)
  elseif !isnothing(dims) # && isnothing(vertices)
    vertices = Tuple.(CartesianIndices(dims))
    @assert prod(dims) == nv(parent_graph)
  end
  return NamedDimDiGraph(parent_graph, vertices)
end

NamedDimDiGraph() = NamedDimDiGraph(DiGraph())

# AbstractNamedGraph required interface.
parent_graph(graph::NamedDimDiGraph) = graph.parent_graph
vertices(graph::NamedDimDiGraph) = graph.vertices
vertex_to_parent_vertex(graph::NamedDimDiGraph) = graph.vertex_to_parent_vertex
edgetype(graph::NamedDimDiGraph{V}) where {V<:Tuple} = NamedDimEdge{V}

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
to_vertex(::Type{<:NamedDimDiGraph}, v...) = tuple_convert(v...)

function has_vertex(graph::NamedDimDiGraph{V}, v::Tuple) where {V<:Tuple}
  return v in vertices(graph)
end

function has_vertex(graph::NamedDimDiGraph, v...)
  return has_vertex(graph, to_vertex(graph, v...))
end

# Customize obtaining subgraphs
# This version takes a list of vertices which are interpreted
# as the subvertices.
function subvertices(graph::NamedDimDiGraph{V}, vertices::Vector) where {V<:Tuple}
  return convert(Vector{V}, tuple_convert.(vertices))
end

# A subset of the original vertices of `graph` based on a
# given slice of the vertices.
function subvertices(graph::NamedDimDiGraph, vertex_slice...)
  return collect(
    keys(getindex(SliceIndex(), graph.vertex_to_parent_vertex, tuple(vertex_slice...)))
  )
end

# TODO: implement in terms of `subvertices` and a generic function
# for dopping the non-slice dimensions like `drop_nonslice_dims`.
# TODO: rename `subvertices_drop_nonslice_dims`.
function sliced_subvertices(graph::NamedDimDiGraph, vertex_slice...)
  return collect(keys(graph.vertex_to_parent_vertex[vertex_slice...]))
end

# TODO: rename `subvertices_drop_nonslice_dims`.
sliced_subvertices(graph::NamedDimDiGraph, vertices::Vector) = subvertices(graph, vertices)

function hvncat(
  dim::Int, graph1::NamedDimDiGraph, graph2::NamedDimDiGraph; new_dim_names=(1, 2)
)
  graph_parent_graph = blockdiag(parent_graph(graph1), parent_graph(graph2))
  graph_vertex_to_parent_vertex = hvncat(
    dim,
    graph1.vertex_to_parent_vertex,
    graph2.vertex_to_parent_vertex;
    new_dim_keys=new_dim_names,
  )
  graph_vertices = collect(keys(graph_vertex_to_parent_vertex))
  return NamedDimDiGraph(graph_parent_graph, graph_vertices)
end

# Overload Graphs.tree. Used for bfs_tree and dfs_tree
# traversal algorithms.
function tree(graph::NamedDimGraph, parents::AbstractVector{T}) where {T<:Tuple}
  n = length(parents)

  # TODO: change to:
  #
  # NamedDimDiGraph(DiGraph(n); vertices=vertices(graph))
  #
  # or:
  #
  # NamedDimDiGraph(vertices(graph))
  t = NamedDimDiGraph{Tuple}(DiGraph(n), vertices(graph))
  for (parent_v, u) in enumerate(parents)
    v = vertices(graph)[parent_v]
    if u != v
      add_edge!(t, u, v)
    end
  end
  return t
end
