struct GenericNamedGraph{V,G<:Graphs.SimpleGraphs.AbstractSimpleGraph} <: AbstractNamedGraph{V}
  parent_graph::G
  vertices::Vector{V}
  vertex_to_parent_vertex::Dictionary{V,Int}
end
function GenericNamedGraph(parent_graph::Graphs.SimpleGraphs.AbstractSimpleGraph, vertices::Vector)
  # Need to copy the vertices here, otherwise the Dictionary uses a view of the vertices
  return GenericNamedGraph(parent_graph, vertices, Dictionary(copy(vertices), eachindex(vertices)))
end
function GenericNamedGraph{V,G}(vertices::Vector) where {V,G}
  return GenericNamedGraph(G(length(vertices)), vertices)
end
GenericNamedGraph{V,G}() where {V,G} = GenericNamedGraph{V,G}(V[])
GenericNamedGraph{<:Any,G}() where {G} = GenericNamedGraph{Any,G}(Any[])
# AbstractNamedGraph required interface.
# TODO: rename `parent_graph` (type is implied by input)
parent_graph_type(::Type{<:GenericNamedGraph{V,G}}) where {V,G} = G
parent_graph(graph::GenericNamedGraph) = graph.parent_graph
vertices(graph::GenericNamedGraph) = graph.vertices
vertex_to_parent_vertex(graph::GenericNamedGraph) = graph.vertex_to_parent_vertex

# TODO: Delete, implemented for AbstractGraph{V}
# vertextype(::Type{<:GenericNamedGraph{V}}) where {V} = V

# TODO: implement as:
# graph = set_parent_graph(graph, copy(parent_graph(graph)))
# graph = set_vertices(graph, copy(vertices(graph)))
copy(graph::GenericNamedGraph) = GenericNamedGraph(copy(parent_graph(graph)), copy(vertices(graph)))

edgetype(G::Type{<:GenericNamedGraph}) = NamedEdge{vertextype(G)}
edgetype(graph::GenericNamedGraph) = edgetype(typeof(graph))

function set_vertices(graph::GenericNamedGraph, vertices)
  return GenericNamedGraph(parent_graph(graph), vertices)
end

directed_graph(G::Type{<:GenericNamedGraph}) = GenericNamedGraph{vertextype(G),directed_graph(parent_graph_type(G))}
undirected_graph(G::Type{<:GenericNamedGraph}) = GenericNamedGraph{vertextype(G),undirected_graph(parent_graph_type(G))}

const NamedGraph{V} = GenericNamedGraph{V,SimpleGraph{Int}}
const NamedDiGraph{V} = GenericNamedGraph{V,SimpleDiGraph{Int}}

# TODO: The generic version isn't working with SimpleTraits for some reason
is_directed(G::Type{<:GenericNamedGraph}) = is_directed(parent_graph_type(G))
# is_directed(::Type{<:NamedGraph}) = false
# is_directed(::Type{<:NamedDiGraph}) = true

function NamedGraph{V}(parent_graph::Graph, vertices::Vector{V}) where {V}
  return NamedGraph{V}(parent_graph, vertices, Dictionary(vertices, eachindex(vertices)))
end

function NamedGraph(parent_graph::Graph, vertices::Vector{V}) where {V}
  return NamedGraph{V}(parent_graph, vertices)
end

function NamedGraph(parent_graph::Graph; dims)
  vertices = Tuple.(CartesianIndices(dims))
  @assert prod(dims) == nv(parent_graph)
  return NamedGraph(parent_graph, vec(vertices))
end

function NamedGraph(vertices::Vector)
  return NamedGraph(Graph(length(vertices)), vertices)
end
