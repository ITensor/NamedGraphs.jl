@eval module $(gensym())
using NamedGraphs.NamedGraphGenerators: named_grid
using NamedGraphs.GraphsExtensions: next_nearest_neighbors, nth_nearest_neighbors
using Test: @test, @testset

#TODO: Add tests for other graphs extensions
@testset "GraphsExtensions" begin
  @testset "Test nth nearest neighbours" begin
    L = 10
    g = named_grid((L, 1))
    vstart = (1, 1)
    @test only(nth_nearest_neighbors(g, vstart, L - 1)) == (L, 1)
    @test only(next_nearest_neighbors(g, vstart)) == (3, 1)

    L = 9
    g = named_grid((L, L))
    v_middle = (ceil(Int64, L / 2), ceil(Int64, L / 2))
    corners = [(L, 1), (1, L), (L, L), (1, 1)]
    @test length(next_nearest_neighbors(g, v_middle)) == 8
    @test issetequal(nth_nearest_neighbors(g, v_middle, L - 1), corners)
  end
end
end
