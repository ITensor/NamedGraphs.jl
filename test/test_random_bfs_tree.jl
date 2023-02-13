using Test
using NamedGraphs
using NamedGraphs: random_bfs_tree
using Graphs
using Random

@testset "Random BFs Tree" begin
  g = named_grid((10, 10))

  s = (5,5)

  Random.seed!(1234)
  g_randtree1 = random_bfs_tree(g, s)
  g_nonrandtree1 = bfs_tree(g, s)
  Random.seed!(1434)
  g_randtree2 = random_bfs_tree(g, s)
  g_nonrandtree2 = bfs_tree(g, s)

  @test length(edges(g_randtree1)) == length(vertices(g_randtree1)) - 1 && is_connected(g_randtree1)
  @test length(edges(g_randtree2)) == length(vertices(g_randtree2)) - 1 && is_connected(g_randtree2)

  @test edges(g_randtree1) != edges(g_randtree2)
  @test edges(g_nonrandtree1) == edges(g_nonrandtree2)
end
