module NamedGraphs
using AbstractTrees
using Dictionaries
using SimpleTraits
using Graphs

using Graphs.SimpleGraphs

# General utility functions
not_implemented() = error("Not implemented")

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

import Base: show, eltype, copy, getindex, convert, hcat, vcat, hvncat, union

# abstractnamededge.jl
import Base: Pair, Tuple, show, ==, hash, eltype, convert
import Graphs: AbstractEdge, src, dst, reverse

include(joinpath("Dictionaries", "dictionary.jl"))
include(joinpath("Graphs", "abstractgraph.jl"))
include(joinpath("Graphs", "simplegraph.jl"))
include(joinpath("Graphs", "generators", "staticgraphs.jl"))
include("abstractnamededge.jl")
include("namededge.jl")
include("abstractnamedgraph.jl")
include("namedgraph.jl")
include(joinpath("generators", "named_staticgraphs.jl"))

export NamedGraph,
  NamedDiGraph,
  NamedEdge,
  vertextype,
  directed_graph,
  undirected_graph,
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
  leaf_vertices,
  vertex_path,
  edge_path,
  subgraph

end # module AbstractNamedGraphs
