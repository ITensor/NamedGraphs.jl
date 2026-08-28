using Dictionaries: AbstractDictionary, AbstractIndices, Dictionary
using Graphs: AbstractEdgeIter, add_edge!, add_vertex!, eccentricity, edges, has_edge,
    has_vertex, ne, neighbors, nv, path_graph, rem_vertex!, vertices, weights
using NamedGraphs: NamedGraphs, NamedEdge, NamedGraph, NamedGridGraph, decoded_edge,
    decoded_vertex, encoded_edge, encoded_graph, encoded_vertex
using Test: @test, @test_throws, @testset

@testset "Vertex codes" begin
    @testset "encoded_vertex and decoded_vertex are inverse bijections" begin
        g = NamedGraph(path_graph(4), ["a", "b", "c", "d"])
        @test all(c -> encoded_vertex(g, decoded_vertex(g, c)) == c, 1:nv(g))
        @test all(v -> decoded_vertex(g, encoded_vertex(g, v)) == v, vertices(g))
        @test sort(map(v -> encoded_vertex(g, v), collect(vertices(g)))) == 1:nv(g)
    end
    @testset "encoded_vertex reports values that aren't vertices" begin
        g = NamedGraph(path_graph(3), ["a", "b", "c"])
        @test_throws ArgumentError encoded_vertex(g, "z")
        @test_throws "\"z\" is not a vertex of the graph" encoded_vertex(g, "z")
        # A value of the wrong type entirely, which is the case that reaches
        # `encoded_vertex` when an argument Graphs.jl would reinterpret by type stays
        # a vertex here.
        gi = NamedGraph(path_graph(3))
        @test_throws "(1, 1) is not a vertex of the graph" encoded_vertex(gi, (1, 1))
        @test_throws "\"z\" is not a vertex of the graph" encoded_vertex(gi, "z")
        @test_throws ArgumentError encoded_vertex(gi, weights(gi))
        # `weights(g)` sits in the vertex position of `eccentricity`, so this has to
        # name the offending value rather than fail converting it to a vertex.
        @test_throws "is not a vertex of the graph" eccentricity(gi, weights(gi))
        # The same report from a graph type that computes codes rather than storing
        # them, including for a coordinate that is outside the grid.
        gg = NamedGridGraph((2, 2))
        @test_throws ArgumentError encoded_vertex(gg, "z")
        @test_throws "\"z\" is not a vertex of the graph" encoded_vertex(gg, "z")
        @test_throws ArgumentError encoded_vertex(gg, (3, 1))
        @test_throws "(3, 1) is not a vertex of the graph" encoded_vertex(gg, (3, 1))
    end
    @testset "Edge codes" begin
        g = NamedGraph(path_graph(3), ["a", "b", "c"])
        e = NamedEdge("a" => "b")
        ce = encoded_edge(g, e)
        @test ce == first(edges(encoded_graph(g)))
        @test decoded_edge(g, ce) == e
    end
    @testset "encoded_graph matches the graph topology" begin
        g = NamedGraph(path_graph(4), ["a", "b", "c", "d"])
        cg = encoded_graph(g)
        @test nv(cg) == nv(g)
        @test ne(cg) == ne(g)
        @test all(e -> has_edge(g, decoded_edge(g, e)), edges(cg))
    end
    @testset "Codes are reassigned by rem_vertex!" begin
        g = NamedGraph(path_graph(4), ["a", "b", "c", "d"])
        rem_vertex!(g, "b")
        @test !has_vertex(g, "b")
        @test nv(g) == 3
        @test all(c -> encoded_vertex(g, decoded_vertex(g, c)) == c, 1:nv(g))
        @test issetequal(neighbors(g, "c"), ["d"])
        @test isempty(neighbors(g, "a"))
        add_vertex!(g, "e")
        @test encoded_vertex(g, "e") == 4
        @test decoded_vertex(g, 4) == "e"
        add_edge!(g, "a" => "e")
        @test has_edge(g, NamedEdge("a" => "e"))
    end
    @testset "Vertex iteration order is insertion order" begin
        g = NamedGraph(path_graph(4), ["v1", "v2", "v3", "v4"])
        rem_vertex!(g, "v2")
        @test collect(vertices(g)) == ["v1", "v3", "v4"]
        @test [decoded_vertex(g, c) for c in 1:nv(g)] == ["v1", "v4", "v3"]
        add_vertex!(g, "v5")
        @test collect(vertices(g)) == ["v1", "v3", "v4", "v5"]
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
        @test es isa AbstractEdgeIter
        @test eltype(es) == NamedEdge{String}
        @test length(es) == 2
        @test NamedEdge("a" => "b") ∈ es
        @test NamedEdge("b" => "a") ∈ es
        @test NamedEdge("a" => "c") ∉ es
        @test issetequal(collect(es), [NamedEdge("a" => "b"), NamedEdge("b" => "c")])
        @test es == edges(NamedGraph(path_graph(3), ["a", "b", "c"]))
        @test es != edges(NamedGraph(path_graph(3), ["a", "c", "b"]))
    end
    @testset "Graph types without a stored coded graph" begin
        g = NamedGridGraph((2, 2))
        @test encoded_graph(g) isa NamedGraphs.EncodedGraphView
        @test encoded_vertex(g, (2, 1)) == 2
        @test decoded_vertex(g, 3) == (1, 2)
        @test (2, 2) ∈ vertices(g)
        @test (3, 1) ∉ vertices(g)
        @test issetequal(
            collect(vertices(g)), [(1, 1), (2, 1), (1, 2), (2, 2)]
        )
        @test last(vertices(g)) == (2, 2)
    end
end
