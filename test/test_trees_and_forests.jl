using Test
using Graphs
using NamedGraphs
using NamedGraphs: forest_cover, spanning_tree

module TestTreesAndForests
using NamedGraphs
using NamedGraphs: hexagonal_lattice_graph, triangular_lattice_graph
gs = [
  ("Chain", named_grid((6, 1))),
  ("Cubic Lattice", named_grid((3, 3, 3))),
  ("Hexagonal Grid", hexagonal_lattice_graph(6, 6)),
  ("Comb Tree", named_comb_tree((4, 4))),
  ("Square lattice", named_grid((10, 10))),
  ("Triangular Grid", triangular_lattice_graph(5, 5; periodic=true)),
]
algs = [NamedGraphs.BFS(), NamedGraphs.DFS(), NamedGraphs.RandomBFS()]
end

@testset "Test Spanning Trees $g_string, $alg" for (g_string, g) in TestTreesAndForests.gs,
  alg in TestTreesAndForests.algs

  s_tree = spanning_tree(g; alg)
  @test is_tree(s_tree)
  @test Set(vertices(s_tree)) == Set(vertices(g))
  @test issubset(Set(edges(s_tree)), Set(edges(g)))
end

@testset "Test Forest Cover $g_string" for (g_string, g) in TestTreesAndForests.gs
  cover = forest_cover(g)
  cover_edges = reduce(vcat, edges.(cover))
  @test issetequal(cover_edges, edges(g))
  @test all(issetequal(vertices(forest), vertices(g)) for forest in cover)
  for forest in cover
    trees = NamedGraph[forest[vs] for vs in connected_components(forest)]
    @test all(is_tree.(trees))
  end
end
