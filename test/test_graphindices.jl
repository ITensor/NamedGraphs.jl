using Dictionaries: Dictionaries, Dictionary
using Graphs: Edge, ne, nv, path_graph, vertices
using NamedGraphs.GraphsExtensions: vertextype
using NamedGraphs: Edges, NamedEdge, NamedGraph, Vertices, to_graph_index
using Test

@testset "Graph indices" begin
    @testset "Vertices/Edges" begin
        vs = [1, 2, 3]
        @test eltype(Vertices(vs)) == eltype(vs)
        @test length(Vertices(vs)) == length(vs)
        @test iterate(Vertices(vs)) == (1, 2)

        es = map(NamedEdge, ["a" => "b", "b" => "c"])
        @test eltype(Edges(es)) == eltype(es)
        @test vertextype(eltype(Edges(es))) == String
    end
    @testset "to_graph_index" begin
        g = path_graph(3)
        @test to_graph_index(g, 1 => 2) isa Edge
        @test to_graph_index(g, Edge(1, 2)) == Edge(1, 2)
        @test to_graph_index(g, "vertex") == "vertex"
        let v = Vertices([1, 2, 3])
            @test to_graph_index(g, v) === v
        end
        let e = Edges([Edge(1, 2), Edge(2, 3)])
            @test to_graph_index(g, e) === e
        end
    end
    # Indexing.jl and Dictionaries.jl dispatch `getindices` on the index
    # container, so a graph needs a method for each of their containers or the
    # calls are ambiguous.
    @testset "getindices index containers" begin
        g = NamedGraph(path_graph(3), ["a", "b", "c"])

        # `:` is every vertex.
        whole = Dictionaries.getindices(g, :)
        @test issetequal(vertices(whole), vertices(g))
        @test ne(whole) == ne(g)

        # An `AbstractIndices` is a set of vertices, and `vertices(g)` is one.
        @test issetequal(vertices(Dictionaries.getindices(g, vertices(g))), vertices(g))
        sub = Dictionaries.getindices(g, Dictionaries.Indices(["a", "b"]))
        @test issetequal(vertices(sub), ["a", "b"])

        # A dictionary is not a set of vertices.
        @test_throws ArgumentError Dictionaries.getindices(g, Dict("a" => "b"))
        @test_throws ArgumentError Dictionaries.getindices(g, Dictionary(["a"], ["b"]))
    end
end
