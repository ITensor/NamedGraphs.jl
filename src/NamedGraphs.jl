module NamedGraphs
import Base:
  convert,
  copy,
  eltype,
  getindex,
  hcat,
  hvncat,
  show,
  to_index,
  to_indices,
  union,
  vcat,
  zero
# abstractnamedgraph.jl
import Graphs:
  a_star,
  add_edge!,
  add_vertex!,
  add_vertices!,
  adjacency_matrix,
  all_neighbors,
  bellman_ford_shortest_paths,
  bfs_parents,
  bfs_tree,
  blockdiag,
  boruvka_mst,
  center,
  common_neighbors,
  connected_components,
  connected_components!,
  degree,
  degree_histogram,
  desopo_pape_shortest_paths,
  diameter,
  dijkstra_shortest_paths,
  dst,
  dfs_parents,
  dfs_tree,
  eccentricity,
  edges,
  edgetype,
  enumerate_paths,
  floyd_warshall_shortest_paths,
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
  johnson_shortest_paths,
  kruskal_mst,
  merge_vertices,
  merge_vertices!,
  mincut,
  ne,
  neighbors,
  neighborhood,
  neighborhood_dists,
  nv,
  outdegree,
  outneighbors,
  prim_mst,
  periphery,
  radius,
  rem_vertex!,
  rem_edge!,
  spfa_shortest_paths,
  src,
  steiner_tree,
  topological_sort_by_dfs,
  tree,
  vertices,
  yen_k_shortest_paths
import SymRCM: symrcm

# abstractnamededge.jl
import Base: Pair, Tuple, show, ==, hash, eltype, convert
import Graphs: AbstractEdge, src, dst, reverse, reverse!

include("lib/Keys/src/Keys.jl")
include("lib/GraphsExtensions/src/GraphsExtensions.jl")
include("utils.jl")
include("abstractnamededge.jl")
include("namededge.jl")
include("abstractnamedgraph.jl")
include("decorate.jl")
include("shortestpaths.jl")
include("distance.jl")
include("distances_and_capacities.jl")
include("steiner_tree/steiner_tree.jl")
include("traversals/dfs.jl")
include("namedgraph.jl")
include("generators/named_staticgraphs.jl")
include("lib/PartitionedGraphs/src/PartitionedGraphs.jl")

export NamedGraph, NamedDiGraph, NamedEdge

# TODO: Move to `NamedGraphs.NamedGraphGenerators`.
# TODO: Add `named_hex`, `named_triangular`, etc.
export named_binary_tree, named_grid, named_path_graph, named_path_digraph

using PackageExtensionCompat: @require_extensions
function __init__()
  @require_extensions
end

end # module AbstractNamedGraphs
