@eval module $(gensym())
using Graphs: edges, ne, vertices
using NamedGraphs.GraphsExtensions: degree, edge_subgraph, is_connected, rem_vertex
using NamedGraphs.NamedGraphGenerators:
    named_comb_tree, named_grid, named_hexagonal_lattice_graph
using NamedGraphs: leafless_edge_induced_subgraphs
using Test: @test, @testset

@testset "leafless_edge_induced_subgraphs" begin
    g = named_comb_tree((3, 3))
    edge_subgraphs = leafless_edge_induced_subgraphs(g, ne(g))
    @test isempty(edge_subgraphs)

    g = named_hexagonal_lattice_graph(3, 3)

    edge_subgraphs = leafless_edge_induced_subgraphs(g, 3)
    @test isempty(edge_subgraphs)

    edge_subgraphs = leafless_edge_induced_subgraphs(g, 6)
    @test all(x -> x == 6, ne.(edge_subgraphs))

    edge_subgraphs = leafless_edge_induced_subgraphs(g, 10)
    @test all(x -> x == 6 || x == 10, ne.(edge_subgraphs))
    # All nodes have degree > 1
    @test all(g -> minimum(degree.((g,), collect(vertices(g)))) > 1, edge_subgraphs)
    @test all(g -> is_connected(g), edge_subgraphs)

    n = 5
    g = named_grid((n, n))
    edge_subgraphs = leafless_edge_induced_subgraphs(g, 4)
    @test length(filter(e -> length(edges(e)) == 4, edge_subgraphs)) == (n - 1) * (n - 1)
    @test length(filter(e -> length(edges(e)) > 4, edge_subgraphs)) == 0

    n = 20
    g = named_grid((n, 1); periodic = true)
    edge_subgraphs = leafless_edge_induced_subgraphs(g, n + 100)
    @test length(edge_subgraphs) == 1
    eg = only(edge_subgraphs)
    @test issetequal(edges(eg), edges(g))
end
end
