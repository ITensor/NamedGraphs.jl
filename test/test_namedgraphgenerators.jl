@eval module $(gensym())
using Graphs: edges, neighbors, vertices
using NamedGraphs.GraphsExtensions: is_cycle_graph
using NamedGraphs.NamedGraphGenerators:
  named_hexagonal_lattice_graph, named_triangular_lattice_graph
using Test: @test, @testset

@testset "Named Graph Generators" begin
  g = named_hexagonal_lattice_graph(1, 1)

  #Should just be 1 hexagon
  @test is_cycle_graph(g)

  #Check consistency with the output of hexagonal_lattice_graph(7,7) in networkx
  g = named_hexagonal_lattice_graph(7, 7)
  @test length(vertices(g)) == 126
  @test length(edges(g)) == 174

  #Check all vertices have degree 3 in the periodic case
  g = named_hexagonal_lattice_graph(6, 6; periodic=true)
  degree_dist = [length(neighbors(g, v)) for v in vertices(g)]
  @test all(d -> d == 3, degree_dist)

  g = named_triangular_lattice_graph(1, 1)

  #Should just be 1 triangle
  @test is_cycle_graph(g)

  g = named_hexagonal_lattice_graph(2, 1)
  dims = maximum(vertices(g))
  @test dims[1] > dims[2]

  g = named_triangular_lattice_graph(2, 1)
  dims = maximum(vertices(g))
  @test dims[1] > dims[2]

  #Check consistency with the output of triangular_lattice_graph(7,7) in networkx
  g = named_triangular_lattice_graph(7, 7)
  @test length(vertices(g)) == 36
  @test length(edges(g)) == 84

  #Check all vertices have degree 6 in the periodic case
  g = named_triangular_lattice_graph(6, 6; periodic=true)
  degree_dist = [length(neighbors(g, v)) for v in vertices(g)]
  @test all(d -> d == 6, degree_dist)
end
end
