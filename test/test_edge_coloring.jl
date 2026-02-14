@eval module $(gensym())
using Graphs: degree, dst, edges, ne, src, vertices
using NamedGraphs.NamedGraphGenerators:
    named_comb_tree, named_grid, named_hexagonal_lattice_graph
using SimpleGraphAlgorithms: edge_color
using SimpleGraphConverter
using Test: @test, @testset

@testset "EdgeColoring" begin
    g = named_grid((4, 4); periodic = true)

    #For bipartite graphs, a coloring can always be achieved, in linear time,
    #using the maximum degree of the graph
    k = maximum([degree(g, v) for v in vertices(g)])
    colored_edges = edge_color(g, k)
    #Test all edges are present in the coloring
    @test issetequal(reduce(vcat, colored_edges), edges(g))
    #Test all colors have same number of edges in this case
    @test all([length(es) == ne(g) / k for es in colored_edges])
    #Test every vertex appears only once in each group (no overlapping edges in the coloring)
    @test all(
        [
            unique(vcat(src.(es), dst.(es))) == vcat(src.(es), dst.(es)) for es in colored_edges
        ]
    )
end
end
