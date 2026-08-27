using Dictionaries: Dictionary
using Graphs: Graphs, AbstractGraph, DiGraph, Graph, SimpleDiGraph, SimpleEdge, SimpleGraph,
    a_star, add_edge!, bellman_ford_shortest_paths, common_neighbors,
    desopo_pape_shortest_paths, dijkstra_shortest_paths, eccentricity, edges, edgetype,
    floyd_warshall_shortest_paths, grid, has_edge, has_path, has_vertex,
    johnson_shortest_paths, ne, nv, path_graph, rem_edge!, spfa_shortest_paths,
    steiner_tree, vertices, weights, yen_k_shortest_paths
using NamedGraphs.GraphsExtensions: GraphsExtensions, eccentricities, edgeless_graph,
    empty_graph, rename_vertices, similar_dataless_graph, similar_graph, subgraph
using NamedGraphs: NamedGraphs, AbstractNamedGraph, NamedDiGraph, NamedEdge, NamedGraph,
    encoded_graph, named_grid, named_path_graph
using Test: @test, @test_throws, @testset

# A callable that is not a `Function`, to check that heuristics are not
# restricted to `Function` subtypes.
struct ZeroHeuristic end
(::ZeroHeuristic)(vertex) = 0

struct TestGraph{V} <: AbstractNamedGraph{V}
    graph::NamedGraph{V}
    TestGraph(graph::NamedGraph{V}) where {V} = new{V}(graph)
end

TestGraph{V}(vertices = V[]) where {V} = TestGraph(NamedGraph(vertices))

function NamedGraphs.similar_graph(g::Type{<:TestGraph}, vertices)
    return TestGraph(similar_graph(NamedGraph, vertices))
end

Graphs.vertices(g::TestGraph) = vertices(g.graph)
Graphs.edges(g::TestGraph) = edges(g.graph)

Graphs.is_directed(::Type{<:TestGraph}) = false

Base.:(==)(g1::TestGraph, g2::TestGraph) = g1.graph == g2.graph

Graphs.edgetype(::Type{<:TestGraph{V}}) where {V} = edgetype(NamedGraph{V})

NamedGraphs.encoded_graph(g::TestGraph) = encoded_graph(g.graph)

Base.copy(g::TestGraph) = TestGraph(copy(g.graph))

@testset "AbstractNamedGraph equality" begin
    # NamedGraph
    g = grid((2, 2))
    vs = ["A", "B", "C", "D"]
    ng1 = NamedGraph(g, vs)
    # construct same NamedGraph with different underlying structure
    ng2 = NamedGraph(Graph(4), vs[[1, 4, 3, 2]])
    add_edge!(ng2, "A" => "B")
    add_edge!(ng2, "A" => "C")
    add_edge!(ng2, "B" => "D")
    add_edge!(ng2, "C" => "D")
    @test NamedGraphs.encoded_graph(ng1) != NamedGraphs.encoded_graph(ng2)
    @test ng1 == ng2
    rem_edge!(ng2, "B" => "A")
    @test ng1 != ng2

    # NamedGraph
    dvs = [("X", 1), ("X", 2), ("Y", 1), ("Y", 2)]
    ndg1 = NamedGraph(g, dvs)
    # construct same NamedGraph from different underlying structure
    ndg2 = NamedGraph(Graph(4), dvs[[1, 4, 3, 2]])
    add_edge!(ndg2, ("X", 1) => ("X", 2))
    add_edge!(ndg2, ("X", 1) => ("Y", 1))
    add_edge!(ndg2, ("X", 2) => ("Y", 2))
    add_edge!(ndg2, ("Y", 1) => ("Y", 2))
    @test NamedGraphs.encoded_graph(ndg1) != NamedGraphs.encoded_graph(ndg2)
    @test ndg1 == ndg2
    rem_edge!(ndg2, ("Y", 1) => ("X", 1))
    @test ndg1 != ndg2

    # NamedDiGraph
    nddg1 = NamedDiGraph(DiGraph(collect(edges(g))), dvs)
    # construct same NamedDiGraph from different underlying structure
    nddg2 = NamedDiGraph(DiGraph(4), dvs[[1, 4, 3, 2]])
    add_edge!(nddg2, ("X", 1) => ("X", 2))
    add_edge!(nddg2, ("X", 1) => ("Y", 1))
    add_edge!(nddg2, ("X", 2) => ("Y", 2))
    add_edge!(nddg2, ("Y", 1) => ("Y", 2))
    @test NamedGraphs.encoded_graph(nddg1) != NamedGraphs.encoded_graph(nddg2)
    @test nddg1 == nddg2
    rem_edge!(nddg2, ("X", 1) => ("Y", 1))
    add_edge!(nddg2, ("Y", 1) => ("X", 1))
    @test nddg1 != nddg2
end

@testset "AbstractNamedGraph vertex renaming" begin
    g = grid((2, 2))
    integer_names = collect(1:4)
    string_names = ["A", "B", "C", "D"]
    tuple_names = [("X", 1), ("X", 2), ("Y", 1), ("Y", 2)]
    function_name = x -> reverse(x)

    # NamedGraph
    ng = NamedGraph(g, string_names)
    # rename to integers
    vmap_int = Dictionary(vertices(ng), integer_names)
    ng_int = rename_vertices(v -> vmap_int[v], ng)
    @test isa(ng_int, NamedGraph{Int})
    @test has_vertex(ng_int, 3)
    @test has_edge(ng_int, 1 => 2)
    @test has_edge(ng_int, 2 => 4)
    # rename to tuples
    vmap_tuple = Dictionary(vertices(ng), tuple_names)
    ng_tuple = rename_vertices(v -> vmap_tuple[v], ng)
    @test isa(ng_tuple, NamedGraph{Tuple{String, Int}})
    @test has_vertex(ng_tuple, ("X", 1))
    @test has_edge(ng_tuple, ("X", 1) => ("X", 2))
    @test has_edge(ng_tuple, ("X", 2) => ("Y", 2))
    # rename with name map function
    ng_function = rename_vertices(function_name, ng_tuple)
    @test isa(ng_function, NamedGraph{Tuple{Int, String}})
    @test has_vertex(ng_function, (1, "X"))
    @test has_edge(ng_function, (1, "X") => (2, "X"))
    @test has_edge(ng_function, (2, "X") => (2, "Y"))

    # NamedGraph
    ndg = named_grid((2, 2))
    # rename to integers
    vmap_int = Dictionary(vertices(ndg), integer_names)
    ndg_int = rename_vertices(v -> vmap_int[v], ndg)
    @test isa(ndg_int, NamedGraph{Int})
    @test has_vertex(ndg_int, 1)
    @test has_edge(ndg_int, 1 => 2)
    @test has_edge(ndg_int, 2 => 4)
    @test length(a_star(ndg_int, 1, 4)) == 2
    # rename to strings
    vmap_string = Dictionary(vertices(ndg), string_names)
    ndg_string = rename_vertices(v -> vmap_string[v], ndg)
    @test isa(ndg_string, NamedGraph{String})
    @test has_vertex(ndg_string, "A")
    @test has_edge(ndg_string, "A" => "B")
    @test has_edge(ndg_string, "B" => "D")
    @test length(a_star(ndg_string, "A", "D")) == 2
    # rename to strings
    vmap_tuple = Dictionary(vertices(ndg), tuple_names)
    ndg_tuple = rename_vertices(v -> vmap_tuple[v], ndg)
    @test isa(ndg_tuple, NamedGraph{Tuple{String, Int}})
    @test has_vertex(ndg_tuple, ("X", 1))
    @test has_edge(ndg_tuple, ("X", 1) => ("X", 2))
    @test has_edge(ndg_tuple, ("X", 2) => ("Y", 2))
    @test length(a_star(ndg_tuple, ("X", 1), ("Y", 2))) == 2
    # rename with name map function
    ndg_function = rename_vertices(function_name, ndg_tuple)
    @test isa(ndg_function, NamedGraph{Tuple{Int, String}})
    @test has_vertex(ndg_function, (1, "X"))
    @test has_edge(ndg_function, (1, "X") => (2, "X"))
    @test has_edge(ndg_function, (2, "X") => (2, "Y"))
    @test length(a_star(ndg_function, (1, "X"), (2, "Y"))) == 2

    # NamedDiGraph
    nddg = NamedDiGraph(DiGraph(collect(edges(g))), vertices(ndg))
    # rename to integers
    vmap_int = Dictionary(vertices(nddg), integer_names)
    nddg_int = rename_vertices(v -> vmap_int[v], nddg)
    @test isa(nddg_int, NamedDiGraph{Int})
    @test has_vertex(nddg_int, 1)
    @test has_edge(nddg_int, 1 => 2)
    @test has_edge(nddg_int, 2 => 4)
    # rename to strings
    vmap_string = Dictionary(vertices(nddg), string_names)
    nddg_string = rename_vertices(v -> vmap_string[v], nddg)
    @test isa(nddg_string, NamedDiGraph{String})
    @test has_vertex(nddg_string, "A")
    @test has_edge(nddg_string, "A" => "B")
    @test has_edge(nddg_string, "B" => "D")
    @test !has_edge(nddg_string, "D" => "B")
    # rename to strings
    vmap_tuple = Dictionary(vertices(nddg), tuple_names)
    nddg_tuple = rename_vertices(v -> vmap_tuple[v], nddg)
    @test isa(nddg_tuple, NamedDiGraph{Tuple{String, Int}})
    @test has_vertex(nddg_tuple, ("X", 1))
    @test has_edge(nddg_tuple, ("X", 1) => ("X", 2))
    @test !has_edge(nddg_tuple, ("Y", 2) => ("X", 2))
    # rename with name map function
    nddg_function = rename_vertices(function_name, nddg_tuple)
    @test isa(nddg_function, NamedDiGraph{Tuple{Int, String}})
    @test has_vertex(nddg_function, (1, "X"))
    @test has_edge(nddg_function, (1, "X") => (2, "X"))
    @test has_edge(nddg_function, (2, "X") => (2, "Y"))
    @test !has_edge(nddg_function, (2, "Y") => (2, "X"))
end

@testset "AbstractNamedGraph `similar_graph`" begin
    ug = named_path_graph(4)
    g = TestGraph(ug)

    @test similar_graph(g) isa NamedGraph
    @test similar_graph(g) == ug
    @test similar_graph(g) !== ug

    @test similar_graph(typeof(g)) isa typeof(g)
    @test similar_graph(typeof(g)) == typeof(g)()
    @test isempty(edges(similar_graph(typeof(g))))
    @test isempty(vertices(similar_graph(typeof(g))))

    @test similar_graph(g, vertices(g)) == typeof(ug)(vertices(g))
    @test similar_graph(typeof(g), vertices(g)) == typeof(g)(vertices(g))
    @test isempty(edges(similar_graph(g, vertices(g))))
    @test isempty(edges(similar_graph(typeof(g), vertices(g))))

    @test similar_graph(g, 2) isa SimpleGraph
    @test nv(similar_graph(g, 2)) == 2
    @test similar_graph(NamedDiGraph([1, 2]), 2) isa SimpleDiGraph
    @test nv(similar_graph(NamedDiGraph([1, 2]), 2)) == 2

    @test nv(empty_graph(ug)) == 0
    @test ne(empty_graph(ug)) == 0

    @test nv(edgeless_graph(ug)) == 4
    @test ne(edgeless_graph(ug)) == 0

    # Make sure the TestGraph is unchanged.
    @test nv(g) == 4
    @test ne(g) == 3

    # similar_dataless_graph
    g = named_path_graph(4)

    @test similar_dataless_graph(g) isa NamedGraph
    @test similar_dataless_graph(g) == g
    @test similar_dataless_graph(NamedDiGraph([1, 2, 3])) isa NamedDiGraph

    @test similar_dataless_graph(g, vertices(g)) == typeof(g)(4)
    @test isempty(edges(similar_dataless_graph(g, vertices(g))))

    sdg = similar_dataless_graph(g, 2)
    @test sdg isa SimpleGraph
    @test nv(sdg) == 2

    sdg = similar_dataless_graph(NamedDiGraph([1, 2, 3]), vertices(g))
    @test similar_dataless_graph(sdg, [1, 2]) isa NamedDiGraph
    @test similar_dataless_graph(sdg, 2) isa SimpleDiGraph
end

# Graphs.jl declares many of its methods with `::Integer` vertex arguments. A
# named graph whose vertices happen to be integers matches those as well as the
# `AbstractNamedGraph` methods, so the wrappers have to mirror the upstream
# signatures or the calls below are ambiguous rather than dispatching to the
# named-graph implementation.
@testset "AbstractNamedGraph with integer vertex names" begin
    g = NamedGraph(path_graph(4))
    named = NamedGraph(path_graph(4), ["a", "b", "c", "d"])

    @test issetequal(common_neighbors(g, 1, 3), [2])
    @test has_path(g, 1, 3)
    @test !has_path(g, 1, 3; exclude_vertices = [2])
    @test eccentricity(g, 1) == 3
    @test dijkstra_shortest_paths(g, 1).dists[4] == 3
    @test spfa_shortest_paths(g, 1)[4] == 3
    @test a_star(g, 1, 3, weights(g)) == [NamedEdge(1 => 2), NamedEdge(2 => 3)]

    # The same calls on a graph with non-integer vertices were never ambiguous,
    # so the two must agree.
    @test issetequal(common_neighbors(named, "a", "c"), ["b"])
    @test eccentricity(named, "a") == eccentricity(g, 1)
    # A vector of sources, since a scalar non-integer vertex is currently read
    # as a collection of sources: see the `dijkstra_shortest_paths` scalar-source
    # gap in the v0.14 plan.
    @test dijkstra_shortest_paths(named, ["a"]).dists["d"] ==
        dijkstra_shortest_paths(g, 1).dists[4]
end

@testset "AbstractNamedGraph a_star arguments" begin
    g = NamedGraph(path_graph(4), [10, 20, 30, 40])

    @test a_star(g, 10, 30) == [NamedEdge(10 => 20), NamedEdge(20 => 30)]

    # `edgetype_to_return` is honored rather than ignored.
    @test a_star(g, 10, 30, weights(g), v -> 0, SimpleEdge) ==
        [SimpleEdge(10, 20), SimpleEdge(20, 30)]
    @test eltype(a_star(named_grid((2, 2)), (1, 1), (2, 2))) ==
        NamedEdge{Tuple{Int, Int}}

    # A callable that is not a `Function` has to reach the named-graph method
    # too, otherwise it silently runs against vertex codes.
    @test a_star(g, 10, 30, weights(g), ZeroHeuristic(), NamedEdge) ==
        a_star(g, 10, 30, weights(g), v -> 0, NamedEdge)
end

@testset "AbstractNamedGraph dijkstra maxdist" begin
    g = NamedGraph(path_graph(4))
    unbounded = dijkstra_shortest_paths(g, 1)
    bounded = dijkstra_shortest_paths(g, 1; maxdist = 1)
    @test unbounded.dists[4] == 3
    @test bounded.dists[4] == typemax(Int)
end

@testset "AbstractNamedGraph eccentricity is singular" begin
    g = NamedGraph(path_graph(4))
    @test eccentricity(g, 1) == 3
    @test eccentricities(g, vertices(g)) == eccentricities(g)
    # A bare distance matrix means "every vertex" in Graphs.jl; here that is
    # `eccentricities`, so the singular form rejects it instead of silently
    # returning a collection.
    @test_throws ErrorException eccentricity(g, weights(g))
end

@testset "AbstractNamedGraph induced_subgraph" begin
    g = named_grid((2, 2))
    sub, _ = Graphs.induced_subgraph(g, [NamedEdge((1, 1) => (1, 2))])
    @test issetequal(vertices(sub), [(1, 1), (1, 2)])
    @test ne(sub) == 1

    # Graphs.jl reads a `Vector{Bool}` as a positional mask. Named graphs make
    # no promise about vertex position, so it is a list of vertex names here.
    gb = NamedGraph([true, false])
    sub, _ = Graphs.induced_subgraph(gb, [true])
    @test issetequal(vertices(sub), [true])
    # Which also means a `Bool` vector is rejected on a graph that has no
    # `Bool` vertices, rather than being read as a mask over the positions.
    @test_throws ArgumentError Graphs.induced_subgraph(g, [true, false])
end

@testset "AbstractNamedGraph subgraph rejects unknown vertices" begin
    g = NamedGraph(path_graph(4))
    @test issetequal(vertices(first(Graphs.induced_subgraph(g, [1, 2]))), [1, 2])
    @test_throws ArgumentError Graphs.induced_subgraph(g, [10, 11])
    @test_throws ArgumentError Graphs.induced_subgraph(g, ["a", "b"])
    @test_throws ArgumentError subgraph(g, [1, 5])
end

# These are not implemented for named graphs. They must error rather than fall
# through to Graphs.jl and run against vertex codes as though those were the
# vertex names, which is what happens without a method mirroring the upstream
# signature.
@testset "AbstractNamedGraph unimplemented shortest paths" begin
    for g in (NamedGraph(path_graph(4)), named_grid((2, 2)))
        v = first(vertices(g))
        @test_throws ErrorException bellman_ford_shortest_paths(g, v)
        @test_throws ErrorException bellman_ford_shortest_paths(g, [v])
        @test_throws ErrorException desopo_pape_shortest_paths(g, v)
        @test_throws ErrorException floyd_warshall_shortest_paths(g, weights(g))
        @test_throws ErrorException johnson_shortest_paths(g, weights(g))
    end
    g = NamedGraph(path_graph(4))
    @test_throws ErrorException yen_k_shortest_paths(g, 1, 3)
end

@testset "AbstractNamedGraph steiner_tree" begin
    g = NamedGraph(path_graph(4))
    @test issetequal(vertices(steiner_tree(g, [1, 3])), [1, 2, 3])
    @test issetequal(vertices(steiner_tree(g, [1, 3], weights(g))), [1, 2, 3])
    gg = named_grid((2, 2))
    tree = steiner_tree(gg, [(1, 1), (2, 2)])
    @test (1, 1) ∈ vertices(tree)
    @test (2, 2) ∈ vertices(tree)
    @test ne(tree) == nv(tree) - 1
end
