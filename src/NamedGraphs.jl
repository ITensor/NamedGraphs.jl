module NamedGraphs
using AbstractTrees
using Dictionaries
using MultiDimDictionaries
using Graphs

using Graphs.SimpleTraits

using MultiDimDictionaries: tuple_convert, IndexType, SliceIndex, ElementIndex

# abstractnamedgraph.jl
import Graphs:
  add_edge!,
  add_vertex!,
  add_vertices!,
  adjacency_matrix,
  all_neighbors,
  bfs_parents,
  bfs_tree,
  blockdiag,
  dst,
  dfs_parents,
  dfs_tree,
  edges,
  edgetype,
  has_edge,
  has_vertex,
  induced_subgraph,
  inneighbors,
  is_connected,
  is_cyclic,
  is_directed,
  is_strongly_connected,
  is_weakly_connected,
  ne,
  neighbors,
  nv,
  outneighbors,
  rem_vertex!,
  rem_edge!,
  src,
  tree,
  vertices

import Base: show, eltype, copy, getindex, convert, hcat, vcat, hvncat

# abstractnamededge.jl
import Base: Pair, Tuple, show, ==, hash, eltype
import Graphs: AbstractEdge, src, dst, reverse
import MultiDimDictionaries: disjoint_union, ⊔

# General utility functions
not_implemented() = error("Not implemented")

include("to_vertex.jl")
include(joinpath("Graphs", "abstractgraph.jl"))
include(joinpath("Graphs", "generators", "staticgraphs.jl"))
include("abstractnamededge.jl")
include("namededge.jl")
include("nameddimedge.jl")
include("abstractnamedgraph.jl")
include("namedgraph.jl")
#include("abstractnameddimgraph.jl") ## TODO
include("nameddimgraph.jl")
include("nameddimdigraph.jl")
include(joinpath("generators", "named_staticgraphs.jl"))

export NamedGraph,
  NamedDimDiGraph,
  NamedDimGraph,
  NamedDimEdge,
  NamedEdge,
  ⊔,
  disjoint_union,
  incident_edges,
  named_binary_tree,
  named_grid,
  comb_tree,
  named_comb_tree,
  post_order_dfs_vertices,
  post_order_dfs_edges,
  rename_vertices,
  # Operations for tree-like graphs
  is_leaf,
  is_tree,
  parent_vertex,
  child_vertices,
  leaf_vertices

end # module AbstractNamedGraphs
