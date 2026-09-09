using Graphs: Graphs, Edge, SimpleGraph, adjacency_matrix, blockdiag, edges, edgetype,
    has_edge, has_vertex, inneighbors, is_directed, ne, neighbors, nv, outneighbors,
    path_graph, vertices
using NamedGraphs: EncodedGraphView, NamedEdge, NamedGraph, NamedGridGraph, encoded_graph,
    rename_vertices, vertextype, ⊔
using Test: @test, @test_broken, @testset

@testset "EncodedGraphView" begin
    g = NamedGridGraph((2, 3))
    pg = EncodedGraphView(g)
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

@testset "EncodedGraphView as a Graphs.jl graph" begin
    g = NamedGridGraph((2, 3))
    @test encoded_graph(g) isa EncodedGraphView
    pg = encoded_graph(g)
    # Graphs.jl algorithms call the `(g, s, d)` form of `has_edge`.
    @test has_edge(pg, 1, 2) == has_edge(pg, Edge(1, 2)) == true
    @test has_edge(pg, 1, 6) == has_edge(pg, Edge(1, 6)) == false
    A = adjacency_matrix(g)
    @test size(A) == (6, 6)
    @test count(!iszero, A) == 2 * ne(g)
end

@testset "EncodedGraphView materializes where a stored graph is needed" begin
    g = NamedGridGraph((2, 3))
    pg = encoded_graph(g)
    c = copy(pg)
    @test c isa SimpleGraph
    @test issetequal(collect(edges(c)), collect(edges(pg)))
    r = rename_vertices(string, g)
    @test r isa NamedGraph{String}
    @test (nv(r), ne(r)) == (nv(g), ne(g))
    h = NamedGraph(path_graph(2), ["a", "b"])
    @test nv(blockdiag(g, h)) == nv(blockdiag(h, g)) == nv(g) + 2
    @test ne(blockdiag(g, h)) == ne(g) + 1
    u = g ⊔ g
    @test (nv(u), ne(u)) == (2 * nv(g), 2 * ne(g))
end
