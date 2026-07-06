@eval module $(gensym())
using Graphs: has_edge, is_connected
using NamedGraphs.GraphsExtensions: add_edges!, rem_edges!
using NamedGraphs.NamedGraphGenerators: named_grid
using NamedGraphs: NamedGraph
using Test: @test, @testset

@testset "Adding and Removing Edge Lists" begin
    g = named_grid((2, 2))
    rem_edges!(g, [(1, 1) => (1, 2), (1, 1) => (2, 1)])
    @test !has_edge(g, (1, 1) => (1, 2))
    @test !has_edge(g, (1, 1) => (2, 1))
    @test has_edge(g, (1, 2) => (2, 2))

    n = 10
    g = NamedGraph([(i,) for i in 1:n])
    add_edges!(g, [(i,) => (i + 1,) for i in 1:(n - 1)])
    @test is_connected(g)
end
end
