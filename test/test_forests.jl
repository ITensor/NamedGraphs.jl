using Test
using Graphs
using NamedGraphs
using NamedGraphs:
  decorate_graph_edges,
  decorate_graph_vertices,
  hexagonal_lattice_graph,
  triangular_lattice_graph,
  build_forest_cover

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
    forest_cover = build_forest_cover(g)
    cover_edges = reduce(vcat, edges.(forest_cover))
    @test issetequal(cover_edges, edges(g))
    for f in forest_cover
      trees = NamedGraph[f[vs] for vs in connected_components(f)]
      @test all(is_tree.(trees))
      @test issetequal(vertices(f), vertices(g))
    end
  end
end
