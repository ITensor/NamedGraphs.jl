module NamedGraphs
using Dictionaries
using MultiDimDictionaries
using Graphs

# abstractnamedgraph.jl
import Graphs:
  src,
  dst,
  nv,
  vertices,
  has_vertex,
  ne,
  edges,
  has_edge,
  neighbors,
  outneighbors,
  inneighbors,
  all_neighbors,
  is_directed,
  add_edge!,
  add_vertex!,
  add_vertices!,
  induced_subgraph,
  adjacency_matrix,
  blockdiag,
  edgetype

import Base: show, eltype, copy, getindex

# abstractnamededge.jl
import Base: Pair, Tuple, show, ==, hash, eltype
import Graphs: AbstractEdge, src, dst, reverse

# General utility functions
not_implemented() = error("Not implemented")

include("abstractnamededge.jl")
include("namededge.jl")
include("abstractnamedgraph.jl")
include("namedgraph.jl")
include("multidimgraph.jl")

export NamedGraph, MultiDimGraph

end # module AbstractNamedGraphs
