module NamedGraphs
using Dictionaries
using MultiDimDictionaries
using Graphs

using MultiDimDictionaries: tuple_convert, IndexType, SliceIndex, ElementIndex

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

import Base: show, eltype, copy, getindex, convert, hcat, vcat, hvncat

# abstractnamededge.jl
import Base: Pair, Tuple, show, ==, hash, eltype
import Graphs: AbstractEdge, src, dst, reverse
import MultiDimDictionaries: disjoint_union, ⊔

# General utility functions
not_implemented() = error("Not implemented")

include("abstractnamededge.jl")
include("namededge.jl")
include("nameddimedge.jl")
include("abstractnamedgraph.jl")
include("namedgraph.jl")
include("nameddimgraph.jl")

export NamedGraph, NamedDimGraph, disjoint_union, ⊔, NamedEdge, NamedDimEdge

end # module AbstractNamedGraphs
