@eval module $(gensym())

using Dictionaries: AbstractDictionary, AbstractIndices, Dictionary
using Graphs: add_edge!, add_vertex!, edges, has_edge, has_vertex, ne, neighbors, nv,
    path_graph, rem_vertex!, vertices
using NamedGraphs.NamedGraphGenerators: NamedGridGraph
using NamedGraphs: NamedGraphs, NamedEdge, NamedGraph, coded_edge, coded_graph,
    coded_vertex, coded_vertices, decoded_edge, decoded_vertex, decoded_vertices
using Test: @test, @testset

@testset "Vertex codes" begin
    @testset "coded_vertex and decoded_vertex are inverse bijections" begin
        g = NamedGraph(path_graph(4), ["a", "b", "c", "d"])
        @test all(c -> coded_vertex(g, decoded_vertex(g, c)) == c, 1:nv(g))
        @test all(v -> decoded_vertex(g, coded_vertex(g, v)) == v, vertices(g))
        @test sort(map(coded_vertex(g), collect(vertices(g)))) == 1:nv(g)
    end
    @testset "decoded_vertices and coded_vertices" begin
        g = NamedGraph(path_graph(3), ["a", "b", "c"])
        dv = decoded_vertices(g)
        @test dv isa AbstractVector{String}
        @test all(c -> dv[c] == decoded_vertex(g, c), 1:nv(g))
        cv = coded_vertices(g)
        @test cv isa AbstractDictionary{String, Int}
        @test all(v -> cv[v] == coded_vertex(g, v), vertices(g))
        # Copies are snapshots that stay valid across graph mutations.
        dv_copy = copy(dv)
        rem_vertex!(g, "a")
        @test dv_copy == ["a", "b", "c"]
        # The outputs themselves are live views of the graph.
        @test length(decoded_vertices(g)) == 2
        @test all(c -> decoded_vertices(g)[c] == decoded_vertex(g, c), 1:nv(g))
        @test all(v -> coded_vertices(g)[v] == coded_vertex(g, v), vertices(g))
    end
    @testset "decoded_vertices and coded_vertices view fallbacks" begin
        g = NamedGridGraph((2, 2))
        dv = decoded_vertices(g)
        @test dv isa AbstractVector{NTuple{2, Int}}
        @test all(c -> dv[c] == decoded_vertex(g, c), 1:nv(g))
        cv = coded_vertices(g)
        @test cv isa AbstractDictionary{NTuple{2, Int}, Int}
        @test all(v -> cv[v] == coded_vertex(g, v), vertices(g))
    end
    @testset "Curried forms" begin
        g = NamedGraph(path_graph(3), ["a", "b", "c"])
        @test map(coded_vertex(g), ["a", "c"]) == [1, 3]
        @test map(decoded_vertex(g), [1, 3]) == ["a", "c"]
    end
    @testset "Edge codes" begin
        g = NamedGraph(path_graph(3), ["a", "b", "c"])
        e = NamedEdge("a" => "b")
        ce = coded_edge(g, e)
        @test ce == first(edges(coded_graph(g)))
        @test decoded_edge(g, ce) == e
    end
    @testset "coded_graph matches the graph topology" begin
        g = NamedGraph(path_graph(4), ["a", "b", "c", "d"])
        cg = coded_graph(g)
        @test nv(cg) == nv(g)
        @test ne(cg) == ne(g)
        @test all(e -> has_edge(g, decoded_edge(g, e)), edges(cg))
    end
    @testset "Codes are reassigned by rem_vertex!" begin
        g = NamedGraph(path_graph(4), ["a", "b", "c", "d"])
        rem_vertex!(g, "b")
        @test !has_vertex(g, "b")
        @test nv(g) == 3
        @test all(c -> coded_vertex(g, decoded_vertex(g, c)) == c, 1:nv(g))
        @test issetequal(neighbors(g, "c"), ["d"])
        @test isempty(neighbors(g, "a"))
        add_vertex!(g, "e")
        @test coded_vertex(g, "e") == 4
        @test decoded_vertex(g, 4) == "e"
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
        @test coded_graph(g) isa NamedGraphs.CodedGraphView
        @test coded_vertex(g, (2, 1)) == 2
        @test decoded_vertex(g, 3) == (1, 2)
        @test (2, 2) ∈ vertices(g)
        @test (3, 1) ∉ vertices(g)
        @test issetequal(
            collect(vertices(g)), [(1, 1), (2, 1), (1, 2), (2, 2)]
        )
        @test last(vertices(g)) == (2, 2)
    end
end

end
