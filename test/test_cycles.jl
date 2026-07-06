@eval module $(gensym())
using Graphs: edges, ne, vertices
using NamedGraphs.GraphsExtensions: degree, edge_subgraph, is_connected, rem_vertex
using NamedGraphs.NamedGraphGenerators:
    named_comb_tree, named_grid, named_hexagonal_lattice_graph
using NamedGraphs: edgeinduced_subgraphs_no_leaves, unique_simplecycles_limited_length
using Test: @test, @testset

@testset "SimpleCycles" begin
    g = named_comb_tree((4, 3))
    @test isempty(unique_simplecycles_limited_length(g, ne(g)))

    g = named_grid((3, 3))
    cycles = unique_simplecycles_limited_length(g, 4)
    @test length(cycles) == 4
    @test Set([(1, 1), (1, 2), (2, 2), (2, 1)]) ∈ Set.(cycles)

    g = rem_vertex(g, (2, 2))
    all_cycles = unique_simplecycles_limited_length(g, ne(g))
    @test length(all_cycles) == 1
    @test Set(vertices(g)) == Set(only(all_cycles))
end

@testset "EdgeInduced_Subgraphs_No_Leaves" begin
    g = named_comb_tree((3, 3))
    edge_subgraphs = edgeinduced_subgraphs_no_leaves(g, ne(g))
    @test isempty(edge_subgraphs)

    g = named_hexagonal_lattice_graph(3, 3)

    edge_subgraphs = edgeinduced_subgraphs_no_leaves(g, 3)
    @test isempty(edge_subgraphs)

    edge_subgraphs = edgeinduced_subgraphs_no_leaves(g, 6)
    @test all(x -> x == 6, ne.(edge_subgraphs))

    edge_subgraphs = edgeinduced_subgraphs_no_leaves(g, 10)
    @test all(x -> x == 6 || x == 10, ne.(edge_subgraphs))
    #All nodes have degree > 1
    @test all(g -> minimum(degree.((g,), collect(vertices(g)))) > 1, edge_subgraphs)
    @test all(g -> is_connected(g), edge_subgraphs)
end
end
