using Graphs
using MultiDimDictionaries
using NamedGraphs
using Test

@testset "MultiDimGraph" begin
  parent_graph = grid((2, 2))
  vertices = [
    ("X", 1),
    ("X", 2),
    ("Y", 1),
    ("Y", 2),
  ]

  g = MultiDimGraph(parent_graph, vertices)

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

  g_sub = g[:, 2]

  @test !has_vertex(g_sub, "X", 1)
  @test has_vertex(g_sub, "X", 2)
  @test !has_vertex(g_sub, "Y", 1)
  @test has_vertex(g_sub, "Y", 2)
end
