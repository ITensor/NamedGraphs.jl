using Dictionaries: AbstractDictionary
using Graphs: Graphs, IsDirected, dst, edges, nv, src
using .GraphsExtensions: directed_graph
using LinearAlgebra: Symmetric
using SimpleTraits: SimpleTraits, Not, @traitfn
using SparseArrays: sparse, spzeros

# TODO: Move to `GraphsExtensions`.
function _symmetrize(dist::AbstractMatrix)
  return sparse(Symmetric(dist))
end

# TODO: Move to `GraphsExtensions`.
function _symmetrize(dist)
  symmetrized_dist = copy(dist)
  for k in keys(dist)
    symmetrized_dist[reverse(k)] = dist[k]
  end
  return symmetrized_dist
end

# TODO: Move to `GraphsExtensions`.
function _symmetrize(dist::AbstractDictionary)
  symmetrized_dist = copy(dist)
  for k in keys(dist)
    insert!(symmetrized_dist, reverse(k), dist[k])
  end
  return symmetrized_dist
end

getindex_dist_matrix(dist_matrix, I...) = dist_matrix[I...]
getindex_dist_matrix(dist_matrix::AbstractDictionary, I...) = dist_matrix[I]

function namedgraph_dist_matrix_to_parent_dist_matrix(
  graph::AbstractNamedGraph, dist_matrix
)
  parent_dist_matrix = spzeros(valtype(dist_matrix), nv(graph), nv(graph))
  for e in edges(graph)
    parent_e = edge_to_parent_edge(graph, e)
    parent_dist_matrix[src(parent_e), dst(parent_e)] = getindex_dist_matrix(
      dist_matrix, src(e), dst(e)
    )
  end
  return parent_dist_matrix
end

@traitfn function dist_matrix_to_parent_dist_matrix(
  graph::AbstractNamedGraph::IsDirected, dist_matrix
)
  return namedgraph_dist_matrix_to_parent_dist_matrix(graph, dist_matrix)
end

@traitfn function dist_matrix_to_parent_dist_matrix(
  graph::AbstractNamedGraph::(!IsDirected), dist_matrix
)
  return _symmetrize(namedgraph_dist_matrix_to_parent_dist_matrix(graph, dist_matrix))
end

function dist_matrix_to_parent_dist_matrix(
  graph::AbstractNamedGraph, distmx::Graphs.DefaultDistance
)
  return distmx
end

"""
    DefaultNamedCapacity{T}

Structure that returns `1` if a forward edge exists in `flow_graph`, and `0` otherwise.
"""
struct DefaultNamedCapacity{G<:AbstractNamedGraph,T<:Integer} <: AbstractMatrix{T}
  flow_graph::G
  nv::T
end

DefaultNamedCapacity(graph::AbstractNamedGraph) = DefaultNamedCapacity(graph, nv(graph))

function _symmetrize(dist::DefaultNamedCapacity)
  return DefaultNamedCapacity(directed_graph(dist.flow_graph))
end

# Base.getindex(d::DefaultNamedCapacity{T}, s, t) where {T} = has_edge(d.flow_graph, s, t) ? one(T) : zero(T)
# Base.size(d::DefaultNamedCapacity) = (Int(d.nv), Int(d.nv))
# Base.transpose(d::DefaultNamedCapacity) = DefaultNamedCapacity(reverse(d.flow_graph))
# Base.adjoint(d::DefaultNamedCapacity) = DefaultNamedCapacity(reverse(d.flow_graph))
