@eval module $(gensym())

using Dictionaries: AbstractDictionary, AbstractIndices, Dictionary
using Graphs: add_edge!, add_vertex!, edges, has_edge, has_vertex, ne, neighbors, nv,
    path_graph, rem_vertex!, vertices
using NamedGraphs.NamedGraphGenerators: NamedGridGraph
using NamedGraphs: NamedGraphs, NamedEdge, NamedGraph, decode_edge, decode_vertex,
    encode_edge, encode_graph, encode_vertex
using Test: @test, @testset

@testset "Vertex codes" begin
    @testset "encode_vertex and decode_vertex are inverse bijections" begin
        g = NamedGraph(path_graph(4), ["a", "b", "c", "d"])
        @test all(c -> encode_vertex(g, decode_vertex(g, c)) == c, 1:nv(g))
        @test all(v -> decode_vertex(g, encode_vertex(g, v)) == v, vertices(g))
        @test sort(map(v -> encode_vertex(g, v), collect(vertices(g)))) == 1:nv(g)
    end
    @testset "Edge codes" begin
        g = NamedGraph(path_graph(3), ["a", "b", "c"])
        e = NamedEdge("a" => "b")
        ce = encode_edge(g, e)
        @test ce == first(edges(encode_graph(g)))
        @test decode_edge(g, ce) == e
    end
    @testset "encode_graph matches the graph topology" begin
        g = NamedGraph(path_graph(4), ["a", "b", "c", "d"])
        cg = encode_graph(g)
        @test nv(cg) == nv(g)
        @test ne(cg) == ne(g)
        @test all(e -> has_edge(g, decode_edge(g, e)), edges(cg))
    end
    @testset "Codes are reassigned by rem_vertex!" begin
        g = NamedGraph(path_graph(4), ["a", "b", "c", "d"])
        rem_vertex!(g, "b")
        @test !has_vertex(g, "b")
        @test nv(g) == 3
        @test all(c -> encode_vertex(g, decode_vertex(g, c)) == c, 1:nv(g))
        @test issetequal(neighbors(g, "c"), ["d"])
        @test isempty(neighbors(g, "a"))
        add_vertex!(g, "e")
        @test encode_vertex(g, "e") == 4
        @test decode_vertex(g, 4) == "e"
        add_edge!(g, "a" => "e")
        @test has_edge(g, NamedEdge("a" => "e"))
    end
    @testset "vertices output" begin
        g = NamedGraph(path_graph(3), ["a", "b", "c"])
        vs = vertices(g)
        @test vs isa AbstractIndices{String}
        @test length(vs) == 3
        @test "b" ∈ vs
        @test "x" ∉ vs
        @test issetequal(collect(vs), ["a", "b", "c"])
        d = map(uppercase, vs)
        @test d isa Dictionary{String, String}
        @test d["b"] == "B"
    end
    @testset "edges output" begin
        g = NamedGraph(path_graph(3), ["a", "b", "c"])
        es = edges(g)
        @test es isa AbstractIndices{NamedEdge{String}}
        @test length(es) == 2
        @test NamedEdge("a" => "b") ∈ es
        @test NamedEdge("b" => "a") ∈ es
        @test NamedEdge("a" => "c") ∉ es
        @test issetequal(collect(es), [NamedEdge("a" => "b"), NamedEdge("b" => "c")])
        d = map(e -> 1, es)
        @test d isa Dictionary{NamedEdge{String}, Int}
        @test d[NamedEdge("a" => "b")] == 1
    end
    @testset "Graph types without a stored coded graph" begin
        g = NamedGridGraph((2, 2))
        @test encode_graph(g) isa NamedGraphs.EncodedGraphView
        @test encode_vertex(g, (2, 1)) == 2
        @test decode_vertex(g, 3) == (1, 2)
        @test (2, 2) ∈ vertices(g)
        @test (3, 1) ∉ vertices(g)
        @test issetequal(
            collect(vertices(g)), [(1, 1), (2, 1), (1, 2), (2, 2)]
        )
        @test last(vertices(g)) == (2, 2)
    end
end

end
