module NamedGraphs

export ⊔, AbstractNamedGraph, NamedDiGraph, NamedEdge, NamedGraph, NamedGridGraph,
    decode_edge, decode_vertex, disjoint_union, encode_edge, encode_vertex,
    encoded_graph, named_binary_tree, named_comb_tree, named_cycle_graph, named_grid,
    named_hexagonal_lattice_graph, named_path_digraph, named_path_graph,
    named_triangular_lattice_graph, rename_vertices
if VERSION >= v"1.11.0-DEV.469"
    eval(Meta.parse("public GraphsExtensions, PartitionedGraphs"))
end

include("similartype.jl")
include("GraphsExtensions/GraphsExtensions.jl")
include("utils.jl")
include("abstractnamededge.jl")
include("namededge.jl")
include("abstractnamedgraph.jl")
include("graph_unions.jl")
include("indicesviews.jl")
include("abstractgraphindices.jl")
include("similar_graph.jl")
include("decorate.jl")
include("shortestpaths.jl")
include("distance.jl")
include("distances_and_capacities.jl")
include("steiner_tree.jl")
include("dfs.jl")
include("namedgraph.jl")
include("encodedgraphview.jl")
include("simplecycles.jl")
include("namedgraphgenerators.jl")
include("namedgridgraph.jl")
include("PartitionedGraphs/PartitionedGraphs.jl")

end
