@eval module $(gensym())
using Graphs: a_star, edges, vertices
# TODO: Move to `NamedGraphGenerators`.
using NamedGraphs: named_grid
# TODO: Rename `named_hexagonal_lattice_graph`, move to `NamedGraphGenerators`.
using NamedGraphs: hexagonal_lattice_graph
using NamedGraphs.GraphsExtensions: decorate_graph_edges, decorate_graph_vertices
using Test: @test, @testset

@testset "Decorated Graphs" begin
  L = 4
  g_2d = named_grid((L, L))

  #Lieb lattice (loops are size 8)
  g_2d_Lieb = decorate_graph_edges(g_2d)

  #Heavier Lieb lattice (loops are size 16)
  g_2d_Lieb_heavy = decorate_graph_edges(g_2d; edge_map=e -> named_grid((3,)))

  #Another way to make the above graph
  g_2d_Lieb_heavy_alt = decorate_graph_edges(g_2d_Lieb)

  #Test they are the same (FUTURE: better way to test if two graphs are same with different vertex names - their adjacency matrices should be related by a permutation matrix)
  @test length(vertices(g_2d_Lieb_heavy)) == length(vertices(g_2d_Lieb_heavy_alt))
  @test length(edges(g_2d_Lieb_heavy)) == length(edges(g_2d_Lieb_heavy_alt))

  #Test right number of edges 
  @test length(edges(g_2d_Lieb)) == 2 * length(edges(g_2d))
  @test length(edges(g_2d_Lieb_heavy)) == 4 * length(edges(g_2d))

  #Test new distances
  @test length(a_star(g_2d, (1, 1), (2, 2))) == 2
  @test length(a_star(g_2d_Lieb, (1, 1), (2, 2))) == 4
  @test length(a_star(g_2d_Lieb_heavy, (1, 1), (2, 2))) == 8

  #Create Hexagon (loops are size 6)
  g_hexagon = hexagonal_lattice_graph(3, 6)

  #Create Heavy Hexagon (loops are size 12)
  g_heavy_hexagon = decorate_graph_edges(g_hexagon)

  #Test heavy hexagon properties
  @test length(vertices(g_heavy_hexagon)) == 125
  @test length(a_star(g_hexagon, (1, 1), (2, 3))) == 3
  @test length(a_star(g_heavy_hexagon, (1, 1), (2, 3))) == 6

  #Create a comb 
  g_1d = named_grid((L, 1))
  g_comb = decorate_graph_vertices(g_1d; vertex_map=v -> named_grid((5,)))
  @test length(vertices(g_comb)) == 5 * length(vertices(g_1d))
  @test length(a_star(g_1d, (1, 1), (L, 1))) ==
    length(a_star(g_comb, ((1,), (1, 1)), ((1,), (L, 1))))
end
end
