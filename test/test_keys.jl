@eval module $(gensym())
using Dictionaries: Dictionary
using NamedGraphs.Keys: Key
using Test: @test, @test_throws, @testset

@testset "Tree Base extensions" begin
  @testset "Test Key indexing" begin
    @test Key(1, 2) == Key((1, 2))

    A = randn(2, 2)
    @test A[1, 2] == A[Key(CartesianIndex(1, 2))]
    @test A[2] == A[Key(2)]
    @test_throws ErrorException A[Key(1, 2)]

    A = randn(4)
    @test A[2] == A[Key(2)]
    @test A[2] == A[Key(CartesianIndex(2))]

    A = Dict("X" => 2, "Y" => 3)
    @test A["X"] == A[Key("X")]

    A = Dictionary(["X", "Y"], [1, 2])
    @test A["X"] == A[Key("X")]
  end
end
end
