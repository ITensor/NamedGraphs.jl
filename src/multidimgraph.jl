struct NamedDimGraph{V<:Tuple} <: AbstractNamedGraph{V}
  parent_graph::Graph{Int}
  vertices::Vector{V}
  vertex_to_parent_vertex::MultiDimDictionary{V,Int}
end

function NamedDimGraph{V}(parent_graph::Graph, vertices::Vector{V}) where {V<:Tuple}
  return NamedDimGraph{V}(
    parent_graph, vertices, MultiDimDictionary{V}(vertices, eachindex(vertices))
  )
end

function NamedDimGraph{V}(parent_graph::Graph, vertices::Vector) where {V<:Tuple}
  graph_vertices = tuple_convert.(vertices)
  return NamedDimGraph{V}(
    parent_graph,
    graph_vertices,
    MultiDimDictionary{Tuple}(graph_vertices, eachindex(graph_vertices)),
  )
end

function NamedDimGraph{V}(parent_graph::Graph, vertices::Array) where {V<:Tuple}
  return NamedDimGraph{V}(parent_graph, vec(vertices))
end

function NamedDimGraph(parent_graph::Graph, vertices::Array)
  # Could default to `eltype(vertices)`, but in general
  # we want the flexibility of `Tuple` for mixed key lengths
  # and types.
  return NamedDimGraph{Tuple}(parent_graph, vertices)
end

function NamedDimGraph(parent_graph::Graph; dims)
  @assert prod(dims) == nv(parent_graph)
  vertices = Tuple.(CartesianIndices(dims))
  return NamedDimGraph(parent_graph, vertices)
end

# AbstractNamedGraph required interface.
parent_graph(graph::NamedDimGraph) = graph.parent_graph
vertices(graph::NamedDimGraph) = graph.vertices
function vertex_to_parent_vertex(graph::NamedDimGraph, vertex...)
  return graph.vertex_to_parent_vertex[vertex...]
end

edgetype(graph::NamedDimGraph{V}) where {V<:Tuple} = NamedDimEdge{V}

function has_vertex(graph::NamedDimGraph{V}, v::Tuple) where {V<:Tuple}
  return v in vertices(graph)
end

function has_vertex(graph::NamedDimGraph, v...)
  return has_vertex(graph, tuple(v...))
end

# Customize obtaining subgraphs
# This version takes a list of vertices which are interpreted
# as the subvertices.
function subvertices(graph::NamedDimGraph{V}, vertices::Vector) where {V<:Tuple}
  return convert(Vector{V}, tuple_convert.(vertices))
end

# A subset of the original vertices of `graph` based on a
# given slice of the vertices.
function subvertices(graph::NamedDimGraph, vertex_slice...)
  return collect(
    keys(
      MultiDimDictionaries.getindex(
        MultiDimDictionaries.SliceIndex(),
        graph.vertex_to_parent_vertex,
        tuple(vertex_slice...),
      ),
    ),
  )
end

# TODO: implement in terms of `subvertices` and a generic function
# for dopping the non-slice dimensions like `drop_nonslice_dims`.
# TODO: rename `subvertices_drop_nonslice_dims`.
function sliced_subvertices(graph::NamedDimGraph, vertex_slice...)
  return collect(keys(graph.vertex_to_parent_vertex[vertex_slice...]))
end

# TODO: rename `subvertices_drop_nonslice_dims`.
sliced_subvertices(graph::NamedDimGraph, vertices::Vector) = subvertices(graph, vertices)

function hvncat(
  dim::Int, graph1::NamedDimGraph, graph2::NamedDimGraph; new_dim_names=(1, 2)
)
  graph_parent_graph = blockdiag(parent_graph(graph1), parent_graph(graph2))
  graph_vertex_to_parent_vertex = hvncat(
    dim,
    graph1.vertex_to_parent_vertex,
    graph2.vertex_to_parent_vertex;
    new_dim_keys=new_dim_names,
  )
  graph_vertices = collect(keys(graph_vertex_to_parent_vertex))
  return NamedDimGraph(graph_parent_graph, graph_vertices)
end

function vcat(graph1::NamedDimGraph, graph2::NamedDimGraph; kwargs...)
  return hvncat(1, graph1, graph2; kwargs...)
end

function hcat(graph1::NamedDimGraph, graph2::NamedDimGraph; kwargs...)
  return hvncat(2, graph1, graph2; kwargs...)
end

# TODO: define `disjoint_union(graphs...; dim::Int, new_dim_names)` to do a disjoint union
# of a number of graphs.
function disjoint_union(graph1::NamedDimGraph, graph2::NamedDimGraph; dim::Int=0, kwargs...)
  return hvncat(dim, graph1, graph2; kwargs...)
end

function ⊔(graph1::NamedDimGraph, graph2::NamedDimGraph; kwargs...)
  return disjoint_union(graph1, graph2; kwargs...)
end
