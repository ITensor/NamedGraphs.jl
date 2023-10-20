using Test
using NamedGraphs
using NamedGraphs:
  add_edges,
  add_edges!,
  rem_edges,
  rem_edges!,
  hexagonal_lattice_graph,
  triangular_lattice_graph
using Graphs

g = hexagonal_lattice_graph(6, 6; periodic=false)

g = triangular_lattice_graph(7, 7; periodic=true)
