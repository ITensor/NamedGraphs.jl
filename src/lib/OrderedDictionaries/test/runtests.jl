@eval module $(gensym())
using Dictionaries: Dictionary
using NamedGraphs.OrderedDictionaries:
  OrderedDictionaries, OrderedDictionary, OrderedIndices, each_ordinal_index
using NamedGraphs.OrdinalIndexing: th
using Test: @test, @testset
@testset "OrderedDictionaries" begin
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
    @test "x1" ∈ i
    @test !("x2" ∈ i)
    @test "x3" ∈ i
    @test "x4" ∈ i
    @test i[1th] == "x1"
    @test i[2th] == "x4"
    @test i[3th] == "x3"
    @test OrderedDictionaries.ordered_indices(i) == ["x1", "x4", "x3"]
    @test OrderedDictionaries.index_positions(i) ==
      Dictionary(["x1", "x3", "x4"], [1, 3, 2])

    # Test for deleting the last index, this is a special
    # case in the code.
    i = OrderedIndices(["x1", "x2", "x3", "x4"])
    delete!(i, "x4")
    @test length(i) == 3
    @test collect(i) == ["x1", "x2", "x3"]
    @test i["x1"] == "x1"
    @test i["x2"] == "x2"
    @test i["x3"] == "x3"
    @test "x1" ∈ i
    @test "x2" ∈ i
    @test "x3" ∈ i
    @test !("x4" ∈ i)
    @test i[1th] == "x1"
    @test i[2th] == "x2"
    @test i[3th] == "x3"
    @test OrderedDictionaries.ordered_indices(i) == ["x1", "x2", "x3"]
    @test OrderedDictionaries.index_positions(i) ==
      Dictionary(["x1", "x2", "x3"], [1, 2, 3])

    i = OrderedIndices(["x1", "x2", "x3", "x4"])
    d = Dictionary(["x1", "x2", "x3", "x4"], [:x1, :x2, :x3, :x4])
    mapped_i = map(i -> d[i], i)
    @test mapped_i == Dictionary(["x1", "x2", "x3", "x4"], [:x1, :x2, :x3, :x4])
    @test mapped_i == OrderedDictionary(["x1", "x2", "x3", "x4"], [:x1, :x2, :x3, :x4])
    @test mapped_i isa OrderedDictionary{String,Symbol}
    @test mapped_i["x1"] === :x1
    @test mapped_i["x2"] === :x2
    @test mapped_i["x3"] === :x3
    @test mapped_i["x4"] === :x4

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

    i = OrderedIndices(["x1", "x2", "x3"])
    d = Dictionary(["x1", "x2", "x3"], zeros(Int, 3))
    for _ in 1:50
      r = rand(i)
      @test r ∈ i
      d[r] += 1
    end
    for k in i
      @test d[k] > 0
    end
  end
  @testset "OrderedDictionaries" begin
    d = OrderedDictionary(["x1", "x2", "x3"], [1, 2, 3])
    @test d["x1"] == 1
    @test d["x2"] == 2
    @test d["x3"] == 3

    d = OrderedDictionary(["x1", "x2", "x3"], [1, 2, 3])
    d["x2"] = 4
    @test d["x1"] == 1
    @test d["x2"] == 4
    @test d["x3"] == 3

    d = OrderedDictionary(["x1", "x2", "x3"], [1, 2, 3])
    @test d[1th] == 1
    @test d[2th] == 2
    @test d[3th] == 3
  end
end
end
