module NamedGraphGenerators

export NamedGridGraph, named_binary_tree, named_comb_tree, named_grid,
    named_hexagonal_lattice_graph, named_path_digraph, named_path_graph,
    named_triangular_lattice_graph

include("graphgenerators.jl")
include("namedgridgraph.jl")

end
