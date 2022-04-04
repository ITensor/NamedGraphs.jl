using Graphs
using MultiDimDictionaries
using NamedGraphs
using Test

@testset "MultiDimGraph" begin
  parent_graph = grid((2, 2))
  vertices = [
    CartesianKey("X", "X"),
    CartesianKey("X", "Y"),
    CartesianKey("Y", "X"),
    CartesianKey("Y", "Y"),
  ]

  g = MultiDimGraph(parent_graph, vertices)

  @test has_vertex(g, CartesianKey("X", "X"))
  @test has_edge(g, CartesianKey("X", "X") => CartesianKey("X", "Y"))

  io = IOBuffer()
  show(io, "text/plain", g)
  @test String(take!(io)) isa String

  g_sub = g[[CartesianKey("X", "X")]]

  @test has_vertex(g_sub, CartesianKey("X", "X"))
  @test !has_vertex(g_sub, CartesianKey("X", "Y"))
  @test !has_vertex(g_sub, CartesianKey("Y", "X"))
  @test !has_vertex(g_sub, CartesianKey("Y", "Y"))

  g_sub = g[[CartesianKey("X", "X"), CartesianKey("X", "Y")]]

  @test has_vertex(g_sub, CartesianKey("X", "X"))
  @test has_vertex(g_sub, CartesianKey("X", "Y"))
  @test !has_vertex(g_sub, CartesianKey("Y", "X"))
  @test !has_vertex(g_sub, CartesianKey("Y", "Y"))

  g_sub = g["X", :]

  @test has_vertex(g_sub, CartesianKey("X", "X"))
  @test has_vertex(g_sub, CartesianKey("X", "Y"))
  @test !has_vertex(g_sub, CartesianKey("Y", "X"))
  @test !has_vertex(g_sub, CartesianKey("Y", "Y"))

  g_sub = g[:, "Y"]

  @test !has_vertex(g_sub, CartesianKey("X", "X"))
  @test has_vertex(g_sub, CartesianKey("X", "Y"))
  @test !has_vertex(g_sub, CartesianKey("Y", "X"))
  @test has_vertex(g_sub, CartesianKey("Y", "Y"))
end
