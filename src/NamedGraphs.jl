module NamedGraphs
using AbstractTrees
using Dictionaries
using Graphs
using GraphsFlows
using LinearAlgebra
using SimpleTraits
using SparseArrays
using SplitApplyCombine
using SymRCM

using Graphs.SimpleGraphs

# General utility functions
not_implemented() = error("Not implemented")

import Base: show, eltype, copy, getindex, convert, hcat, vcat, hvncat, union, zero
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
  center,
  common_neighbors,
  connected_components,
  connected_components!,
  degree,
  degree_histogram,
  diameter,
  dijkstra_shortest_paths,
  dst,
  dfs_parents,
  dfs_tree,
  eccentricity,
  edges,
  edgetype,
  has_edge,
  has_path,
  has_vertex,
  indegree,
  induced_subgraph,
  inneighbors,
  is_connected,
  is_cyclic,
  is_directed,
  is_strongly_connected,
  is_weakly_connected,
  merge_vertices,
  merge_vertices!,
  mincut,
  ne,
  neighbors,
  neighborhood,
  neighborhood_dists,
  outdegree,
  a_star,
  bellman_ford_shortest_paths,
  enumerate_paths,
  desopo_pape_shortest_paths,
  floyd_warshall_shortest_paths,
  johnson_shortest_paths,
  spfa_shortest_paths,
  yen_k_shortest_paths,
  boruvka_mst,
  kruskal_mst,
  prim_mst,
  nv,
  outneighbors,
  periphery,
  radius,
  rem_vertex!,
  rem_edge!,
  src,
  tree,
  vertices
import SymRCM: symrcm

# abstractnamededge.jl
import Base: Pair, Tuple, show, ==, hash, eltype, convert
import Graphs: AbstractEdge, src, dst, reverse, reverse!

include(joinpath("Dictionaries", "dictionary.jl"))
include(joinpath("Graphs", "abstractgraph.jl"))
include(joinpath("Graphs", "shortestpaths.jl"))
include(joinpath("Graphs", "simplegraph.jl"))
include(joinpath("Graphs", "generators", "staticgraphs.jl"))
include("abstractnamededge.jl")
include("namededge.jl")
include("abstractnamedgraph.jl")
include("shortestpaths.jl")
include("distance.jl")
include("distances_and_capacities.jl")
include("namedgraph.jl")
include(joinpath("generators", "named_staticgraphs.jl"))

# TODO: reexport Graphs.jl (except for `Graphs.contract`)
export NamedGraph,
  NamedDiGraph,
  NamedEdge,
  ⊔,
  named_binary_tree,
  named_grid,
  named_path_graph,
  named_path_digraph,
  # AbstractGraph
  dijkstra_mst,
  dijkstra_parents,
  directed_graph,
  permute_vertices,
  symrcm,
  symrcm_permute,
  undirected_graph,
  vertextype,
  # Graphs.jl
  a_star,
  adjacency_matrix,
  center,
  diameter,
  dijkstra_shortest_paths,
  dijkstra_tree,
  disjoint_union,
  eccentricity,
  eccentricities,
  incident_edges,
  comb_tree,
  named_comb_tree,
  neighborhood,
  neighborhood_dists,
  neighbors,
  path_digraph,
  path_graph,
  periphery,
  post_order_dfs_vertices,
  post_order_dfs_edges,
  radius,
  rename_vertices,
  degree,
  degrees,
  indegree,
  indegrees,
  outdegree,
  outdegrees,
  mincut_partitions,
  weights,
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
