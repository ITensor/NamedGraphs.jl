using Test
using Graphs
using NamedGraphs
using NamedGraphs:
  hexagonal_lattice_graph, triangular_lattice_graph, forest_cover, spanning_tree

@testset "Test Spanning Trees" begin
  gs = [
    named_grid((6, 1)),
    named_grid((3, 3, 3)),
    hexagonal_lattice_graph(6, 6),
    named_comb_tree((4, 4)),
    named_grid((10, 10)),
    triangular_lattice_graph(5, 5; periodic=true),
  ]
  algs = [NamedGraphs.BFS(), NamedGraphs.DFS(), NamedGraphs.RandomBFS()]
  for g in gs
    for alg in algs
      s_tree = spanning_tree(alg, g)
      @test is_tree(s_tree)
      @test Set(vertices(s_tree)) == Set(vertices(g))
      @test issubset(Set(edges(s_tree)), Set(edges(g)))
    end
  end
end

@testset "Test Forest Cover" begin
  gs = [
    named_grid((6, 1)),
    named_grid((3, 3, 3)),
    hexagonal_lattice_graph(6, 6),
    named_comb_tree((4, 4)),
    named_grid((10, 10)),
    triangular_lattice_graph(5, 5; periodic=true),
  ]
  for g in gs
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
