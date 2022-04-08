struct MultiDimGraph{V} <: AbstractNamedGraph{V}
  parent_graph::Graph{Int}
  vertices::Vector{V}
  vertex_to_parent_vertex::MultiDimDictionary{V,Int}
end

function MultiDimGraph{V}(parent_graph::Graph, vertices::Vector) where {V}
  graph_vertices = V.(vertices)
  return MultiDimGraph{V}(
    parent_graph, graph_vertices, MultiDimDictionary{V}(graph_vertices, eachindex(graph_vertices))
  )
end

function MultiDimGraph{V}(parent_graph::Graph, vertices::Array) where {V}
  return MultiDimGraph{V}(parent_graph, vec(vertices))
end

function MultiDimGraph(parent_graph::Graph, vertices::Array)
  # Could default to `eltype(vertices)`, but in general
  # we want the flexibility of `Tuple` for mixed key lengths
  # and types.
  return MultiDimGraph{Tuple}(parent_graph, vertices)
end

function MultiDimGraph(parent_graph::Graph; dims)
  @assert prod(dims) == nv(parent_graph)
  vertices = Tuple.(CartesianIndices(dims))
  return MultiDimGraph(parent_graph, vertices)
end

# AbstractNamedGraph required interface.
parent_graph(graph::MultiDimGraph) = graph.parent_graph
vertices(graph::MultiDimGraph) = graph.vertices
function vertex_to_parent_vertex(graph::MultiDimGraph, vertex...)
  return graph.vertex_to_parent_vertex[vertex...]
end

edgetype(graph::MultiDimGraph{V}) where {V} = MultiDimEdge{V}

function has_vertex(graph::MultiDimGraph{V}, v::Tuple) where {V}
  return v in vertices(graph)
end

function has_vertex(graph::MultiDimGraph, v...)
  return has_vertex(graph, tuple(v...))
end

# Customize obtaining subgraphs
# This version takes a list of vertices which are interpreted
# as the subvertices.
function subvertices(graph::MultiDimGraph{V}, vertices::Vector) where {V}
  return convert(Vector{V}, vertices)
end

# A subset of the original vertices of `graph` based on a
# given slice of the vertices.
function subvertices(graph::MultiDimGraph, vertex_slice...)
  return collect(keys(MultiDimDictionaries.getindex_no_dropdims(MultiDimDictionaries.SliceIndex(), graph.vertex_to_parent_vertex, tuple(vertex_slice...))))
end

function sliced_subvertices(graph::MultiDimGraph, vertex_slice...)
  return collect(keys(graph.vertex_to_parent_vertex[vertex_slice...]))
end

function hvncat(dim::Int, graph1::MultiDimGraph, graph2::MultiDimGraph; new_dim_names=(1, 2))
  graph_parent_graph = blockdiag(parent_graph(graph1), parent_graph(graph2))
  graph_vertex_to_parent_vertex = hvncat(dim, graph1.vertex_to_parent_vertex, graph2.vertex_to_parent_vertex; new_dim_keys=new_dim_names)
  graph_vertices = collect(keys(graph_vertex_to_parent_vertex))
  return MultiDimGraph(graph_parent_graph, graph_vertices)
end

function vcat(graph1::MultiDimGraph, graph2::MultiDimGraph; kwargs...)
  return hvncat(1, graph1, graph2; kwargs...)
end

function hcat(graph1::MultiDimGraph, graph2::MultiDimGraph; kwargs...)
  return hvncat(2, graph1, graph2; kwargs...)
end

# TODO: define `disjoint_union(graphs...; dim::Int, new_dim_names)` to do a disjoint union
# of a number of graphs.
function disjoint_union(graph1::MultiDimGraph, graph2::MultiDimGraph; dim::Int=0, kwargs...)
  return hvncat(dim, graph1, graph2; kwargs...)
end

function ⊔(graph1::MultiDimGraph, graph2::MultiDimGraph; kwargs...)
  return disjoint_union(graph1, graph2; kwargs...)
end
