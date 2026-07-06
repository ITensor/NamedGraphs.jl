@eval module $(gensym())

using Graphs: Graphs, Edge, edges, edgetype, has_edge, has_vertex, inneighbors, is_directed,
    ne, neighbors, nv, outneighbors, vertices
using NamedGraphs.GraphsExtensions: vertextype
using NamedGraphs.NamedGraphGenerators: NamedGridGraph
using NamedGraphs: NamedEdge, PositionGraphView, ordered_vertices, vertex_positions
using Test: @test, @test_broken, @testset

@testset "PositionGraphView" begin
    g = NamedGridGraph((2, 3))
    pg = PositionGraphView(g)
    @test is_directed(typeof(pg)) == is_directed(typeof(g)) == false
    @test nv(pg) == nv(g) == 6
    @test ne(pg) == ne(g)
    @test_broken eltype(edges(pg)) == Edge{Int}
    @test edgetype(pg) == Edge{Int}
    @test vertextype(pg) == Int
    @test vertices(pg) == Base.OneTo(nv(g))
    @test length(edges(pg)) == ne(g)
    @test all(e -> has_edge(pg, e), edges(pg))
end

end
