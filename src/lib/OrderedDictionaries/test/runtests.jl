@eval module $(gensym())
using Dictionaries: Dictionary
using NamedGraphs.OrderedDictionaries: OrderedIndices, each_ordinal_index
using NamedGraphs.OrdinalIndexing: th
using Test: @test, @testset
@testset "OrderedIndices" begin
  i = OrderedIndices(["x1", "x2", "x3", "x4"])
  @test i isa OrderedIndices{String}
  @test length(i) == 4
  @test collect(i) == ["x1", "x2", "x3", "x4"]
  @test eachindex(i) isa OrderedIndices{String}
  @test keys(i) isa OrderedIndices{String}
  @test issetequal(i, ["x1", "x2", "x3", "x4"])
  @test keys(i) == OrderedIndices(["x1", "x2", "x3", "x4"])
  @test issetequal(keys(i), ["x1", "x2", "x3", "x4"])
  @test i["x1"] == "x1"
  @test i["x2"] == "x2"
  @test i["x3"] == "x3"
  @test i["x4"] == "x4"
  @test i[1th] == "x1"
  @test i[2th] == "x2"
  @test i[3th] == "x3"
  @test i[4th] == "x4"

  i = OrderedIndices(["x1", "x2", "x3", "x4"])
  delete!(i, "x2")
  @test length(i) == 3
  @test collect(i) == ["x1", "x4", "x3"]
  @test i["x1"] == "x1"
  @test i["x3"] == "x3"
  @test i["x4"] == "x4"
  @test !("x2" ∈ i)
  @test i[1th] == "x1"
  @test i[2th] == "x4"
  @test i[3th] == "x3"
  @test i.ordered_indices == ["x1", "x4", "x3"]
  @test i.index_ordinals == Dictionary(["x1", "x3", "x4"], [1, 3, 2])

  i = OrderedIndices(["x1", "x2", "x3"])
  insert!(i, "x4")
  @test length(i) == 4
  @test collect(i) == ["x1", "x2", "x3", "x4"]
  @test i["x1"] == "x1"
  @test i["x2"] == "x2"
  @test i["x3"] == "x3"
  @test i["x4"] == "x4"
  @test i[1th] == "x1"
  @test i[2th] == "x2"
  @test i[3th] == "x3"
  @test i[4th] == "x4"

  i = OrderedIndices(["x1", "x2", "x3"])
  ords = each_ordinal_index(i)
  @test ords == (1:3)th
  @test i[ords[1]] == "x1"
  @test i[ords[2]] == "x2"
  @test i[ords[3]] == "x3"
end
end
