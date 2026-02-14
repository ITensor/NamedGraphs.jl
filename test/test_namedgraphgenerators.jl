@eval module $(gensym())

using Graphs: a_star, add_edge!, add_vertex!, degree, edges, edgetype, has_edge, has_vertex,
    is_directed, ne, neighbors, nv, rem_edge!, rem_vertex!, vertices
using NamedGraphs.GraphsExtensions: is_cycle_graph, vertextype
using NamedGraphs.NamedGraphGenerators: NamedGridGraph, grid_ndims, grid_size,
    is_directed_grid, ishypertorus, named_grid, named_hexagonal_lattice_graph,
    named_triangular_lattice_graph
using NamedGraphs: NamedEdge
using Test: @test, @test_throws, @testset

@testset "Named Graph Generators" begin
    g = named_hexagonal_lattice_graph(1, 1)

    #Should just be 1 hexagon
    @test is_cycle_graph(g)

    #Check consistency with the output of hexagonal_lattice_graph(7,7) in networkx
    g = named_hexagonal_lattice_graph(7, 7)
    @test length(vertices(g)) == 126
    @test length(edges(g)) == 174

    #Check all vertices have degree 3 in the periodic case
    g = named_hexagonal_lattice_graph(6, 6; periodic = true)
    degree_dist = [length(neighbors(g, v)) for v in vertices(g)]
    @test all(d -> d == 3, degree_dist)

    g = named_triangular_lattice_graph(1, 1)

    #Should just be 1 triangle
    @test is_cycle_graph(g)

    g = named_hexagonal_lattice_graph(2, 1)
    dims = maximum(vertices(g))
    @test dims[1] > dims[2]

    g = named_triangular_lattice_graph(2, 1)
    dims = maximum(vertices(g))
    @test dims[1] > dims[2]

    #Check consistency with the output of triangular_lattice_graph(7,7) in networkx
    g = named_triangular_lattice_graph(7, 7)
    @test length(vertices(g)) == 36
    @test length(edges(g)) == 84

    #Check all vertices have degree 6 in the periodic case
    g = named_triangular_lattice_graph(6, 6; periodic = true)
    degree_dist = [length(neighbors(g, v)) for v in vertices(g)]
    @test all(d -> d == 6, degree_dist)
end

@testset "NamedGridGraph" begin
    g = NamedGridGraph((4, 4))

    # Grid interface
    @test !ishypertorus(g)
    @test grid_size(g) == (4, 4)
    @test grid_ndims(g) == 2
    @test grid_ndims(typeof(g)) == 2
    @test !is_directed_grid(typeof(g))

    @test !is_directed(g)
    @test nv(g) == length(vertices(g)) == 16
    @test ne(g) == length(edges(g)) == 24
    @test issetequal(neighbors(g, (2, 2)), [(1, 2), (3, 2), (2, 1), (2, 3)])
    @test edgetype(g) == NamedEdge{Tuple{Int, Int}}
    @test vertextype(g) == Tuple{Int, Int}
    @test has_vertex(g, (2, 3))
    @test has_edge(g, (2, 3) => (2, 4))
    @test ((2, 3) => (2, 4)) in edges(g)
    @test issetequal(vertices(g), Tuple.(CartesianIndices((4, 4))))
    @test issetequal(collect(edges(g)), edges(named_grid((4, 4))))
    @test a_star(g, (1, 1), (2, 2)) == NamedEdge.([(1, 1) => (2, 1), (2, 1) => (2, 2)])
    @test_throws ErrorException add_vertex!(g, (1, 1))
    @test_throws ErrorException rem_vertex!(g, (1, 1))
    @test_throws ErrorException add_edge!(g, (1, 1) => (1, 2))
    @test_throws ErrorException rem_edge!(g, (1, 1) => (1, 2))

    g = NamedGridGraph((4, 4), true)
    @test ishypertorus(g)
    @test nv(g) == length(vertices(g)) == 16
    @test ne(g) == length(edges(g)) == 32
    @test all(vertices(g)) do v
        return all(v′ -> degree(g, v′) == 4, neighbors(g, v))
    end

    g = NamedGridGraph((4, 4, 4), true)
    @test ishypertorus(g)
    @test nv(g) == length(vertices(g)) == 64
    @test ne(g) == length(edges(g)) == 192
    @test all(vertices(g)) do v
        return all(v′ -> degree(g, v′) == 6, neighbors(g, v))
    end
end

end
