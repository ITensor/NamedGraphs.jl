using Graphs
using MultiDimDictionaries
using NamedGraphs
using Random
using Test

@testset "NamedDimGraph" begin
  parent_graph = grid((2, 2))
  vertices = [("X", 1), ("X", 2), ("Y", 1), ("Y", 2)]

  g = NamedDimGraph(parent_graph, vertices)

  @test has_vertex(g, "X", 1)
  @test has_edge(g, ("X", 1) => ("X", 2))
  @test !has_edge(g, ("X", 2) => ("Y", 1))
  @test has_edge(g, ("X", 2) => ("Y", 2))

  io = IOBuffer()
  show(io, "text/plain", g)
  @test String(take!(io)) isa String

  g_sub = g[[("X", 1)]]

  @test has_vertex(g_sub, "X", 1)
  @test !has_vertex(g_sub, "X", 2)
  @test !has_vertex(g_sub, "Y", 1)
  @test !has_vertex(g_sub, "Y", 2)

  g_sub = g[[("X", 1), ("X", 2)]]

  @test has_vertex(g_sub, "X", 1)
  @test has_vertex(g_sub, "X", 2)
  @test !has_vertex(g_sub, "Y", 1)
  @test !has_vertex(g_sub, "Y", 2)

  g_sub = g["X", :]

  @test has_vertex(g_sub, "X", 1)
  @test has_vertex(g_sub, "X", 2)
  @test !has_vertex(g_sub, "Y", 1)
  @test !has_vertex(g_sub, "Y", 2)
  @test has_edge(g_sub, ("X", 1) => ("X", 2))

  g_sub = g[:, 2]

  @test has_vertex(g_sub, "X", 2)
  @test has_vertex(g_sub, "Y", 2)
  @test !has_vertex(g_sub, "X", 1)
  @test !has_vertex(g_sub, "Y", 1)
  @test has_edge(g_sub, ("X", 2) => ("Y", 2))

  g1 = NamedDimGraph(grid((2, 2)); dims=(2, 2))

  @test nv(g1) == 4
  @test ne(g1) == 4
  @test has_vertex(g1, 1, 1)
  @test has_vertex(g1, 2, 1)
  @test has_vertex(g1, 1, 2)
  @test has_vertex(g1, 2, 2)
  @test has_edge(g1, (1, 1) => (1, 2))
  @test has_edge(g1, (1, 1) => (2, 1))
  @test has_edge(g1, (1, 2) => (2, 2))
  @test has_edge(g1, (2, 1) => (2, 2))
  @test !has_edge(g1, (1, 1) => (2, 2))

  g2 = NamedDimGraph(grid((2, 2)); dims=(2, 2))

  g = ⊔(g1, g2; new_dim_names=("X", "Y"))

  @test nv(g) == 8
  @test ne(g) == 8
  @test has_vertex(g, "X", 1, 1)
  @test has_vertex(g, "Y", 1, 1)

  # TODO: Need to drop the dimensions to make these equal
  #@test issetequal(Graphs.vertices(g1), Graphs.vertices(g["X", :]))
  #@test issetequal(edges(g1), edges(g["X", :]))
  #@test issetequal(Graphs.vertices(g1), Graphs.vertices(g["Y", :]))
  #@test issetequal(edges(g1), edges(g["Y", :]))
end

@testset "NamedDimGraph add vertices" begin
  parent_graph = grid((2, 2))
  vertices = [("X", 1), ("X", 2), ("Y", 1), ("Y", 2)]
  g = NamedDimGraph()
  add_vertex!(g, "X", 1)
  add_vertex!(g, "X", 2)
  add_vertex!(g, ("Y", 1))
  add_vertex!(g, "Y", 2)

  @test nv(g) == 4
  @test ne(g) == 0
  @test has_vertex(g, "X", 1)
  @test has_vertex(g, "X", 2)
  @test has_vertex(g, "Y", 1)
  @test has_vertex(g, "Y", 2)

  add_edge!(g, ("X", 1) => ("Y", 2))

  @test ne(g) == 1
  @test has_edge(g, ("X", 1) => ("Y", 2))
end
