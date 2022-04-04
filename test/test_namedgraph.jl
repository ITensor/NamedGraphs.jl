using Graphs
using NamedGraphs
using Test

@testset "NamedGraph" begin
  g = NamedGraph(grid((4,)), ["A", "B", "C", "D"])

  @test has_vertex(g, "A")
  @test has_vertex(g, "B")
  @test has_vertex(g, "C")
  @test has_vertex(g, "D")
  @test has_edge(g, "A" => "B")

  io = IOBuffer()
  show(io, "text/plain", g)
  @test String(take!(io)) isa String

  add_edge!(g, "A" => "C")

  @test has_edge(g, "A" => "C")
  @test issetequal(neighbors(g, "A"), ["B", "C"])
  @test issetequal(neighbors(g, "B"), ["A", "C"])

  g_sub = g[["A", "B"]]

  @test has_vertex(g_sub, "A")
  @test has_vertex(g_sub, "B")
  @test !has_vertex(g_sub, "C")
  @test !has_vertex(g_sub, "D")
end
