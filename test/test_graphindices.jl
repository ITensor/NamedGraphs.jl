@eval module $(gensym())
using Test
using Graphs: Edge, path_graph
using NamedGraphs: Vertices, Edges, to_graph_index, NamedEdge
using NamedGraphs.GraphsExtensions: vertextype

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
end
end
