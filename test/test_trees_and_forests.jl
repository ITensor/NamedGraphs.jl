@eval module $(gensym())
using Test: @test, @testset
using Graphs: connected_components, edges, is_tree, vertices
using NamedGraphs: NamedGraph
# TODO: Move to `NamedGraphGenerators`.
using NamedGraphs: named_comb_tree, named_grid
# TODO: Move to `NamedGraphGenerators`, rename to `named_f(...)`.
using NamedGraphs: hexagonal_lattice_graph, triangular_lattice_graph
using NamedGraphs.GraphsExtensions: GraphsExtensions, all_edges, forest_cover, spanning_tree

gs = [
  ("Chain", named_grid((6, 1))),
  ("Cubic Lattice", named_grid((3, 3, 3))),
  ("Hexagonal Grid", hexagonal_lattice_graph(6, 6)),
  ("Comb Tree", named_comb_tree((4, 4))),
  ("Square lattice", named_grid((10, 10))),
  ("Triangular Grid", triangular_lattice_graph(5, 5; periodic=true)),
]
algs = (GraphsExtensions.BFS(), GraphsExtensions.DFS(), GraphsExtensions.RandomBFS())

@testset "Test Spanning Trees $g_string, $alg" for (g_string, g) in gs, alg in algs
  s_tree = spanning_tree(g; alg)
  @test is_tree(s_tree)
  @test issetequal(vertices(s_tree), vertices(g))
  @test issubset(all_edges(s_tree), all_edges(g))
end

@testset "Test Forest Cover $g_string" for (g_string, g) in gs
  cover = forest_cover(g)
  cover_edges = reduce(vcat, edges.(cover))
  @test issetequal(cover_edges, edges(g))
  @test all(issetequal(vertices(forest), vertices(g)) for forest in cover)
  for forest in cover
    trees = NamedGraph[forest[vs] for vs in connected_components(forest)]
    @test all(is_tree.(trees))
  end
end
end
