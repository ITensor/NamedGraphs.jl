using Graphs: a_star, add_edge!, add_vertex!, degree, dst, edges, edgetype, has_edge,
    has_vertex, is_directed, ne, neighbors, nv, rem_edge!, rem_vertex!, src, vertices
using NamedGraphs: NamedEdge, NamedGridGraph, decode_vertex, encode_vertex, grid_ndims,
    grid_size, is_cycle_graph, is_directed_grid, ishypertorus, named_binary_tree,
    named_cycle_graph, named_grid, named_hexagonal_lattice_graph,
    named_triangular_lattice_graph, vertextype
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

@testset "named_cycle_graph" begin
    g = named_cycle_graph(4)
    @test nv(g) == 4
    @test ne(g) == 4
    @test issetequal(vertices(g), 1:4)
    @test is_cycle_graph(g)
end

@testset "named_binary_tree" begin
    g = named_binary_tree(3)
    @test nv(g) == 7
    @test ne(g) == 6
    # The path-from-root labels share a concrete element type, so `vertextype`
    # is concrete (the point of naming vertices this way).
    @test vertextype(g) == Vector{Int}
    @test issetequal(
        vertices(g),
        [[1], [1, 1], [1, 2], [1, 1, 1], [1, 1, 2], [1, 2, 1], [1, 2, 2]]
    )
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

    # `has_vertex` answers with a `Bool` for any value, as generic Graphs.jl code
    # that guards with it expects, and not just for grid coordinates.
    @test has_vertex(g, (1, 1))
    @test has_vertex(g, (Int32(2), Int32(3)))
    @test !has_vertex(g, (5, 2))
    @test !has_vertex(g, (0, 1))
    @test !has_vertex(g, (typemax(UInt64), 1))
    @test !has_vertex(g, "abc")
    @test !has_vertex(g, (1, 2, 3))
    @test !has_vertex(g, (1.0, 2.0))
    @test !has_vertex(g, 1)
    @test !has_vertex(g, nothing)

    @test all(v -> decode_vertex(g, encode_vertex(g, v)) == v, vertices(g))
    @test all(c -> encode_vertex(g, decode_vertex(g, c)) == c, 1:nv(g))
    @test encode_vertex(g, (Int32(2), Int32(3))) == encode_vertex(g, (2, 3))
    @test_throws ArgumentError encode_vertex(g, "abc")
    @test_throws ArgumentError encode_vertex(g, (5, 2))

    @test_throws ArgumentError neighbors(g, "abc")
    @test_throws ArgumentError neighbors(g, (5, 2))

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

    # Stepping off the boundary of a hypertorus wraps around to the far side, so `ne`,
    # `edges`, `has_edge`, and `neighbors` all have to agree on the same edge set.
    for sz in ((3, 4), (4, 4), (3, 4, 5), (4, 4, 4))
        g = NamedGridGraph(sz, true)
        es = collect(edges(g))
        @test ne(g) == length(es)
        @test all(e -> has_vertex(g, src(e)) && has_vertex(g, dst(e)), es)
        @test all(e -> has_edge(g, src(e), dst(e)), es)
        @test all(v -> degree(g, v) == 2 * grid_ndims(g), vertices(g))
        @test all(v -> all(n -> has_vertex(g, n), neighbors(g, v)), vertices(g))
        @test_throws ArgumentError neighbors(g, "abc")
        @test_throws ArgumentError neighbors(g, sz .+ 1)
    end

    g = NamedGridGraph((3, 4), true)
    @test issetequal(neighbors(g, (1, 1)), [(3, 1), (2, 1), (1, 4), (1, 2)])
    @test issetequal(neighbors(g, (3, 4)), [(2, 4), (1, 4), (3, 3), (3, 1)])
    @test issetequal(neighbors(g, (2, 1)), [(1, 1), (3, 1), (2, 4), (2, 2)])
    @test issetequal(neighbors(g, (2, 2)), [(1, 2), (3, 2), (2, 1), (2, 3)])

    g = NamedGridGraph((3, 4, 5), true)
    @test issetequal(
        neighbors(g, (1, 1, 1)),
        [(3, 1, 1), (2, 1, 1), (1, 4, 1), (1, 2, 1), (1, 1, 5), (1, 1, 2)]
    )
    @test issetequal(
        neighbors(g, (3, 4, 5)),
        [(2, 4, 5), (1, 4, 5), (3, 3, 5), (3, 1, 5), (3, 4, 4), (3, 4, 1)]
    )

    # Wrapping a dimension of size 1 or 2 would produce self-loops or doubled edges,
    # so a hypertorus needs every dimension to have size 3 or more.
    for sz in ((2, 2), (1, 3), (3, 2), (1, 1), (3, 3, 2))
        @test_throws ArgumentError NamedGridGraph(sz, true)
        @test_throws ArgumentError NamedGridGraph{length(sz), true}(sz)
    end

    # Only the periodic case is constrained, so the same sizes stay legal without wrapping.
    for (sz, nv_sz, ne_sz) in (
            ((2, 2), 4, 4),
            ((1, 3), 3, 2),
            ((3, 2), 6, 7),
            ((1, 1), 1, 0),
            ((3, 3, 2), 18, 33),
        )
        g = NamedGridGraph(sz)
        @test !ishypertorus(g)
        @test nv(g) == length(vertices(g)) == nv_sz
        @test ne(g) == length(edges(g)) == ne_sz
    end

    g = NamedGridGraph((3, 3), true)
    @test ishypertorus(g)
    @test nv(g) == length(vertices(g)) == 9
    @test ne(g) == length(edges(g)) == 18
    @test all(v -> degree(g, v) == 2 * grid_ndims(g), vertices(g))
end
