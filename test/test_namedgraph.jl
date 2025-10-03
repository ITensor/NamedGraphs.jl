@eval module $(gensym())
using Dictionaries: Dictionary, Indices
using Graphs:
    Edge,
    δ,
    Δ,
    a_star,
    add_edge!,
    add_vertex!,
    adjacency_matrix,
    bellman_ford_shortest_paths,
    bfs_parents,
    bfs_tree,
    boruvka_mst,
    center,
    common_neighbors,
    connected_components,
    degree,
    degree_histogram,
    desopo_pape_shortest_paths,
    dfs_parents,
    dfs_tree,
    diameter,
    dijkstra_shortest_paths,
    dst,
    eccentricity,
    edges,
    edgetype,
    floyd_warshall_shortest_paths,
    grid,
    has_edge,
    has_path,
    has_self_loops,
    has_vertex,
    indegree,
    is_connected,
    is_cyclic,
    is_directed,
    is_ordered,
    johnson_shortest_paths,
    kruskal_mst,
    merge_vertices,
    ne,
    neighborhood,
    neighborhood_dists,
    neighbors,
    nv,
    outdegree,
    path_digraph,
    path_graph,
    periphery,
    prim_mst,
    radius,
    rem_vertex!,
    spfa_shortest_paths,
    src,
    steiner_tree,
    topological_sort_by_dfs,
    vertices,
    yen_k_shortest_paths
using Graphs.SimpleGraphs: SimpleDiGraph, SimpleEdge
using GraphsFlows: GraphsFlows
using NamedGraphs: AbstractNamedEdge, NamedEdge, NamedDiGraph, NamedGraph
using NamedGraphs.GraphsExtensions:
    GraphsExtensions,
    ⊔,
    boundary_edges,
    boundary_vertices,
    convert_vertextype,
    degrees,
    eccentricities,
    dijkstra_mst,
    dijkstra_parents,
    dijkstra_tree,
    has_vertices,
    incident_edges,
    indegrees,
    inner_boundary_vertices,
    mincut_partitions,
    outdegrees,
    outer_boundary_vertices,
    permute_vertices,
    rename_vertices,
    subgraph,
    symrcm_perm,
    symrcm_permute,
    vertextype
using NamedGraphs.NamedGraphGenerators: named_binary_tree, named_grid, named_path_graph
using SymRCM: SymRCM
using Test: @test, @test_broken, @testset

@testset "NamedEdge" begin
    @test NamedEdge(SimpleEdge(1, 2)) == NamedEdge(1, 2)
    @test AbstractNamedEdge(SimpleEdge(1, 2)) == NamedEdge(1, 2)
    @test is_ordered(NamedEdge("A", "B"))
    @test !is_ordered(NamedEdge("B", "A"))
    @test rename_vertices(NamedEdge("A", "B"), Dict(["A" => "C", "B" => "D"])) ==
        NamedEdge("C", "D")
    @test rename_vertices(SimpleEdge(1, 2), Dict([1 => "C", 2 => "D"])) == NamedEdge("C", "D")
    @test rename_vertices(v -> Dict(["A" => "C", "B" => "D"])[v], NamedEdge("A", "B")) ==
        NamedEdge("C", "D")
    @test rename_vertices(v -> Dict([1 => "C", 2 => "D"])[v], SimpleEdge(1, 2)) ==
        NamedEdge("C", "D")
end

@testset "NamedGraph" begin
    @testset "Basics" begin
        g = NamedGraph(grid((4,)), ["A", "B", "C", "D"])
        @test nv(g) == 4
        @test ne(g) == 3
        @test sum(g) == 3
        @test has_vertex(g, "A")
        @test has_vertex(g, "B")
        @test has_vertex(g, "C")
        @test has_vertex(g, "D")
        @test has_edge(g, "A" => "B")
        @test issetequal(common_neighbors(g, "A", "C"), ["B"])
        @test isempty(common_neighbors(g, "A", "D"))
        @test degree(g, "A") == 1
        @test degree(g, "B") == 2

        g = NamedGraph(grid((4,)), [2, 4, 6, 8])
        g_t = convert_vertextype(UInt16, g)
        @test g == g_t
        @test nv(g_t) == 4
        @test ne(g_t) == 3
        @test vertextype(g_t) === UInt16
        @test issetequal(vertices(g_t), UInt16[2, 4, 6, 8])
        @test eltype(vertices(g_t)) === UInt16

        g = NamedGraph(grid((4,)), ["A", "B", "C", "D"])
        zg = zero(g)
        @test zg isa NamedGraph{String}
        @test nv(zg) == 0
        @test ne(zg) == 0

        g = NamedGraph(grid((4,)), ["A", "B", "C", "D"])
        add_vertex!(g, "E")
        @test has_vertex(g, "E")
        @test nv(g) == 5
        @test has_vertices(g, ["A", "B", "C", "D", "E"])

        g = NamedGraph(grid((5,)), ["A", "B", "C", "D", "E"])
        rem_vertex!(g, "E")
        @test !has_vertex(g, "E")

        g = NamedGraph(grid((4,)), ["A", "B", "C", "D"])
        add_vertex!(g, "E")
        rem_vertex!(g, "E")
        @test !has_vertex(g, "E")

        g = NamedGraph(grid((4,)), ["A", "B", "C", "D"])
        for gc in (NamedGraph(g), convert(NamedGraph, g))
            @test gc == g
            @test gc isa NamedGraph{String}
            @test vertextype(gc) === vertextype(g)
            @test issetequal(vertices(gc), vertices(g))
            @test issetequal(edges(gc), edges(g))
        end
        for gc in (NamedGraph{Any}(g), convert(NamedGraph{Any}, g))
            @test gc == g
            @test gc isa NamedGraph{Any}
            @test vertextype(gc) === Any
            @test issetequal(vertices(gc), vertices(g))
            @test issetequal(edges(gc), edges(g))
        end

        io = IOBuffer()
        show(io, "text/plain", g)
        @test String(take!(io)) isa String

        add_edge!(g, "A" => "C")

        @test has_edge(g, "A" => "C")
        @test issetequal(neighbors(g, "A"), ["B", "C"])
        @test issetequal(neighbors(g, "B"), ["A", "C"])

        g_sub = subgraph(g, ["A", "B"])

        @test has_vertex(g_sub, "A")
        @test has_vertex(g_sub, "B")
        @test !has_vertex(g_sub, "C")
        @test !has_vertex(g_sub, "D")
        # Test Graphs.jl `getindex` syntax.
        @test g_sub == g[["A", "B"]]

        g = NamedGraph(["A", "B", "C", "D", "E"])
        add_edge!(g, "A" => "B")
        add_edge!(g, "B" => "C")
        add_edge!(g, "D" => "E")
        @test has_path(g, "A", "B")
        @test has_path(g, "A", "C")
        @test has_path(g, "D", "E")
        @test !has_path(g, "A", "E")

        g = named_path_graph(4)
        @test degree(g, 1) == 1
        @test indegree(g, 1) == 1
        @test outdegree(g, 1) == 1
        @test degree(g, 2) == 2
        @test indegree(g, 2) == 2
        @test outdegree(g, 2) == 2
        @test Δ(g) == 2
        @test δ(g) == 1
    end
    @testset "neighborhood" begin
        g = named_grid((4, 4))
        @test issetequal(neighborhood(g, (1, 1), nv(g)), vertices(g))
        @test issetequal(neighborhood(g, (1, 1), 0), [(1, 1)])
        @test issetequal(neighborhood(g, (1, 1), 1), [(1, 1), (2, 1), (1, 2)])
        ns = [(1, 1), (2, 1), (1, 2), (3, 1), (2, 2), (1, 3)]
        @test issetequal(neighborhood(g, (1, 1), 2), ns)
        ns = [(1, 1), (2, 1), (1, 2), (3, 1), (2, 2), (1, 3), (4, 1), (3, 2), (2, 3), (1, 4)]
        @test issetequal(neighborhood(g, (1, 1), 3), ns)
        ns = [
            (1, 1),
            (2, 1),
            (1, 2),
            (3, 1),
            (2, 2),
            (1, 3),
            (4, 1),
            (3, 2),
            (2, 3),
            (1, 4),
            (4, 2),
            (3, 3),
            (2, 4),
        ]
        @test issetequal(neighborhood(g, (1, 1), 4), ns)
        ns = [
            (1, 1),
            (2, 1),
            (1, 2),
            (3, 1),
            (2, 2),
            (1, 3),
            (4, 1),
            (3, 2),
            (2, 3),
            (1, 4),
            (4, 2),
            (3, 3),
            (2, 4),
            (4, 3),
            (3, 4),
        ]
        @test issetequal(neighborhood(g, (1, 1), 5), ns)
        @test issetequal(neighborhood(g, (1, 1), 6), vertices(g))
        ns_ds = [
            ((1, 1), 0),
            ((2, 1), 1),
            ((1, 2), 1),
            ((3, 1), 2),
            ((2, 2), 2),
            ((1, 3), 2),
            ((4, 1), 3),
            ((3, 2), 3),
            ((2, 3), 3),
            ((1, 4), 3),
        ]
        @test issetequal(neighborhood_dists(g, (1, 1), 3), ns_ds)

        # Test ambiguity with Graphs.jl AbstractGraph definition
        g = named_path_graph(5)
        @test issetequal(neighborhood(g, 3, 1), [2, 3, 4])
        @test issetequal(neighborhood_dists(g, 3, 1), [(2, 1), (3, 0), (4, 1)])
    end
    @testset "Basics (directed)" begin
        g = NamedDiGraph(["A", "B", "C", "D"])
        add_edge!(g, "A" => "B")
        add_edge!(g, "B" => "C")
        @test has_edge(g, "A" => "B")
        @test has_edge(g, "B" => "C")
        @test !has_edge(g, "B" => "A")
        @test !has_edge(g, "C" => "B")
        @test indegree(g, "A") == 0
        @test outdegree(g, "A") == 1
        @test indegree(g, "B") == 1
        @test outdegree(g, "B") == 1
        @test indegree(g, "C") == 1
        @test outdegree(g, "C") == 0
        @test indegree(g, "D") == 0
        @test outdegree(g, "D") == 0

        @test degrees(g) == Dictionary(vertices(g), [1, 2, 1, 0])
        @test degrees(g, ["B", "C"]) == [2, 1]
        @test degrees(g, Indices(["B", "C"])) == Dictionary(["B", "C"], [2, 1])
        @test indegrees(g) == Dictionary(vertices(g), [0, 1, 1, 0])
        @test outdegrees(g) == Dictionary(vertices(g), [1, 1, 0, 0])

        h = degree_histogram(g)
        @test h[0] == 1
        @test h[1] == 2
        @test h[2] == 1

        h = degree_histogram(g, indegree)
        @test h[0] == 2
        @test h[1] == 2
    end
    @testset "BFS traversal" begin
        g = named_grid((3, 3))
        t = bfs_tree(g, (1, 1))
        @test is_directed(t)
        @test t isa NamedDiGraph{Tuple{Int, Int}}
        @test ne(t) == 8
        edges = [
            (1, 1) => (1, 2),
            (1, 2) => (1, 3),
            (1, 1) => (2, 1),
            (2, 1) => (2, 2),
            (2, 2) => (2, 3),
            (2, 1) => (3, 1),
            (3, 1) => (3, 2),
            (3, 2) => (3, 3),
        ]
        for e in edges
            @test has_edge(t, e)
        end

        p = bfs_parents(g, (1, 1))
        @test length(p) == 9
        vertices_g = [(1, 1), (2, 1), (3, 1), (1, 2), (2, 2), (3, 2), (1, 3), (2, 3), (3, 3)]
        parent_vertices = [
            (1, 1), (1, 1), (2, 1), (1, 1), (2, 1), (3, 1), (1, 2), (2, 2), (3, 2),
        ]
        d = Dictionary(vertices_g, parent_vertices)
        for v in vertices(g)
            @test p[v] == d[v]
        end

        g = named_grid(3)
        t = bfs_tree(g, 2)
        @test is_directed(t)
        @test t isa NamedDiGraph{Int}
        @test ne(t) == 2
        @test has_edge(g, 2 => 1)
        @test has_edge(g, 2 => 3)
    end
    @testset "DFS traversal" begin
        g = named_grid((3, 3))
        t = dfs_tree(g, (1, 1))
        @test is_directed(t)
        @test t isa NamedDiGraph{Tuple{Int, Int}}
        @test ne(t) == 8
        edges = [
            (1, 1) => (2, 1),
            (2, 1) => (3, 1),
            (3, 1) => (3, 2),
            (3, 2) => (2, 2),
            (2, 2) => (1, 2),
            (1, 2) => (1, 3),
            (1, 3) => (2, 3),
            (2, 3) => (3, 3),
        ]
        for e in edges
            @test has_edge(t, e)
        end

        p = dfs_parents(g, (1, 1))
        @test length(p) == 9
        vertices_g = [(1, 1), (2, 1), (3, 1), (1, 2), (2, 2), (3, 2), (1, 3), (2, 3), (3, 3)]
        parent_vertices = [
            (1, 1), (1, 1), (2, 1), (2, 2), (3, 2), (3, 1), (1, 2), (1, 3), (2, 3),
        ]
        d = Dictionary(vertices_g, parent_vertices)
        for v in vertices(g)
            @test p[v] == d[v]
        end

        g = named_grid(3)
        t = dfs_tree(g, 2)
        @test is_directed(t)
        @test t isa NamedDiGraph{Int}
        @test ne(t) == 2
        @test has_edge(g, 2 => 1)
        @test has_edge(g, 2 => 3)
    end
    @testset "Shortest paths" begin
        g = named_grid((10, 10))
        p = a_star(g, (1, 1), (10, 10))
        @test length(p) == 18
        @test eltype(p) == edgetype(g)
        @test eltype(p) == NamedEdge{Tuple{Int, Int}}

        ps = spfa_shortest_paths(g, (1, 1))
        @test ps isa Dictionary{Tuple{Int, Int}, Int}
        @test length(ps) == 100
        @test ps[(8, 1)] == 7

        es, weights = boruvka_mst(g)
        @test length(es) == 99
        @test weights == 99
        @test es isa Vector{NamedEdge{Tuple{Int, Int}}}

        es = kruskal_mst(g)
        @test length(es) == 99
        @test es isa Vector{NamedEdge{Tuple{Int, Int}}}

        es = prim_mst(g)
        @test length(es) == 99
        @test es isa Vector{NamedEdge{Tuple{Int, Int}}}

        for f in (
                bellman_ford_shortest_paths,
                desopo_pape_shortest_paths,
                dijkstra_shortest_paths,
                floyd_warshall_shortest_paths,
                johnson_shortest_paths,
                yen_k_shortest_paths,
            )
            @test_broken f(g, "A")
        end
    end
    @testset "Graph connectivity" begin
        g = NamedGraph(2)
        @test g isa NamedGraph{Int}
        add_edge!(g, 1, 2)
        @test !has_self_loops(g)
        add_edge!(g, 1, 1)
        @test has_self_loops(g)

        g1 = named_grid((2, 2))
        g2 = named_grid((2, 2))
        g = g1 ⊔ g2
        t = named_binary_tree(3)

        @test is_cyclic(g1)
        @test is_cyclic(g2)
        @test is_cyclic(g)
        @test !is_cyclic(t)

        @test is_connected(g1)
        @test is_connected(g2)
        @test !is_connected(g)
        @test is_connected(t)

        cc = connected_components(g1)
        @test length(cc) == 1
        @test length(only(cc)) == nv(g1)
        @test issetequal(only(cc), vertices(g1))

        cc = connected_components(g)
        @test length(cc) == 2
        @test length(cc[1]) == nv(g1)
        @test length(cc[2]) == nv(g2)
        @test issetequal(cc[1], map(v -> (v, 1), vertices(g1)))
        @test issetequal(cc[2], map(v -> (v, 2), vertices(g2)))
    end
    @testset "incident_edges" begin
        g = grid((3, 3))
        inc_edges = Edge.([2 => 1, 2 => 3, 2 => 5])
        @test issetequal(incident_edges(g, 2), inc_edges)
        @test issetequal(incident_edges(g, 2; dir = :in), reverse.(inc_edges))
        @test issetequal(incident_edges(g, 2; dir = :out), inc_edges)
        @test issetequal(incident_edges(g, 2; dir = :both), inc_edges ∪ reverse.(inc_edges))

        g = named_grid((3, 3))
        inc_edges = NamedEdge.([(2, 1) => (1, 1), (2, 1) => (3, 1), (2, 1) => (2, 2)])
        @test issetequal(incident_edges(g, (2, 1)), inc_edges)
        @test issetequal(incident_edges(g, (2, 1); dir = :in), reverse.(inc_edges))
        @test issetequal(incident_edges(g, (2, 1); dir = :out), inc_edges)
        @test issetequal(incident_edges(g, (2, 1); dir = :both), inc_edges ∪ reverse.(inc_edges))

        g = path_digraph(4)
        @test issetequal(incident_edges(g, 3), Edge.([3 => 4]))
        @test issetequal(incident_edges(g, 3; dir = :in), Edge.([2 => 3]))
        @test issetequal(incident_edges(g, 3; dir = :out), Edge.([3 => 4]))
        @test issetequal(incident_edges(g, 3; dir = :both), Edge.([2 => 3, 3 => 4]))

        g = NamedDiGraph(path_digraph(4), ["A", "B", "C", "D"])
        @test issetequal(incident_edges(g, "C"), NamedEdge.(["C" => "D"]))
        @test issetequal(incident_edges(g, "C"; dir = :in), NamedEdge.(["B" => "C"]))
        @test issetequal(incident_edges(g, "C"; dir = :out), NamedEdge.(["C" => "D"]))
        @test issetequal(
            incident_edges(g, "C"; dir = :both), NamedEdge.(["B" => "C", "C" => "D"])
        )
    end
    @testset "merge_vertices" begin
        g = named_grid((3, 3))
        mg = merge_vertices(g, [(2, 2), (2, 3), (3, 3)])
        @test nv(mg) == 7
        @test ne(mg) == 9
        merged_vertices = [(1, 1), (2, 1), (3, 1), (1, 2), (2, 2), (3, 2), (1, 3)]
        for v in merged_vertices
            @test has_vertex(mg, v)
        end
        merged_edges = [
            (1, 1) => (2, 1),
            (1, 1) => (1, 2),
            (2, 1) => (3, 1),
            (2, 1) => (2, 2),
            (3, 1) => (3, 2),
            (1, 2) => (2, 2),
            (1, 2) => (1, 3),
            (2, 2) => (3, 2),
            (2, 2) => (1, 3),
        ]
        for e in merged_edges
            @test has_edge(mg, e)
        end

        sg = SimpleDiGraph(4)
        g = NamedDiGraph(sg, ["A", "B", "C", "D"])
        add_edge!(g, "A" => "B")
        add_edge!(g, "B" => "C")
        add_edge!(g, "C" => "D")
        mg = merge_vertices(g, ["B", "C"])
        @test ne(mg) == 2
        @test has_edge(mg, "A" => "B")
        @test has_edge(mg, "B" => "D")

        sg = SimpleDiGraph(4)
        g = NamedDiGraph(sg, ["A", "B", "C", "D"])
        add_edge!(g, "B" => "A")
        add_edge!(g, "C" => "B")
        add_edge!(g, "D" => "C")
        mg = merge_vertices(g, ["B", "C"])
        @test ne(mg) == 2
        @test has_edge(mg, "B" => "A")
        @test has_edge(mg, "D" => "B")
    end
    @testset "mincut" begin
        g = NamedGraph(path_graph(4), ["A", "B", "C", "D"])

        part1, part2, flow = GraphsFlows.mincut(g, "A", "D")
        @test "A" ∈ part1
        @test "D" ∈ part2
        @test flow == 1

        part1, part2 = mincut_partitions(g, "A", "D")
        @test "A" ∈ part1
        @test "D" ∈ part2

        part1, part2 = mincut_partitions(g)
        @test issetequal(vcat(part1, part2), vertices(g))

        weights_dict = Dict{Tuple{String, String}, Float64}()
        weights_dict["A", "B"] = 3
        weights_dict["B", "C"] = 2
        weights_dict["C", "D"] = 3

        weights_dictionary = Dictionary(keys(weights_dict), values(weights_dict))

        for weights in (weights_dict, weights_dictionary)
            part1, part2, flow = GraphsFlows.mincut(g, "A", "D", weights)
            @test issetequal(part1, ["A", "B"]) || issetequal(part1, ["C", "D"])
            @test issetequal(vcat(part1, part2), vertices(g))
            @test flow == 2

            part1, part2 = mincut_partitions(g, "A", "D", weights)
            @test issetequal(part1, ["A", "B"]) || issetequal(part1, ["C", "D"])
            @test issetequal(vcat(part1, part2), vertices(g))

            part1, part2 = mincut_partitions(g, weights)
            @test issetequal(part1, ["A", "B"]) || issetequal(part1, ["C", "D"])
            @test issetequal(vcat(part1, part2), vertices(g))
        end
    end
    @testset "dijkstra" begin
        g = named_grid((3, 3))

        srcs = [(1, 1), (2, 1), (3, 1), (1, 2), (2, 2), (3, 2), (1, 3), (2, 3), (3, 3)]
        dsts = [(2, 1), (2, 2), (2, 1), (2, 2), (2, 2), (2, 2), (2, 3), (2, 2), (2, 3)]
        parents = Dictionary(srcs, dsts)

        d = dijkstra_shortest_paths(g, [(2, 2)])
        @test d.dists == Dictionary(vertices(g), [2, 1, 2, 1, 0, 1, 2, 1, 2])
        @test d.parents == parents
        @test d.pathcounts ==
            Dictionary(vertices(g), [2.0, 1.0, 2.0, 1.0, 1.0, 1.0, 2.0, 1.0, 2.0])

        # Regression test
        # https://github.com/mtfishman/NamedGraphs.jl/pull/34
        vertex_map = v -> v[1] > 1 ? (v, 1) : v
        g̃ = rename_vertices(vertex_map, g)
        d = dijkstra_shortest_paths(g̃, [((2, 2), 1)])
        @test d.dists == Dictionary(vertices(g̃), [2, 1, 2, 1, 0, 1, 2, 1, 2])
        @test d.parents == Dictionary(map(vertex_map, srcs), map(vertex_map, dsts))
        @test d.pathcounts ==
            Dictionary(vertices(g̃), [2.0, 1.0, 2.0, 1.0, 1.0, 1.0, 2.0, 1.0, 2.0])

        t = dijkstra_tree(g, (2, 2))
        @test nv(t) == 9
        @test ne(t) == 8
        @test issetequal(vertices(t), vertices(g))
        for v in vertices(g)
            if parents[v] ≠ v
                @test has_edge(t, parents[v] => v)
            end
        end

        p = dijkstra_parents(g, (2, 2))
        @test p == parents

        mst = dijkstra_mst(g, (2, 2))
        @test length(mst) == 8
        for e in mst
            @test parents[src(e)] == dst(e)
        end

        g = named_grid(4)

        srcs = [1, 2, 3, 4]
        dsts = [2, 2, 2, 3]
        parents = Dictionary(srcs, dsts)

        d = dijkstra_shortest_paths(g, [2])
        @test d.dists == Dictionary(vertices(g), [1, 0, 1, 2])
        @test d.parents == parents
        @test d.pathcounts == Dictionary(vertices(g), [1.0, 1.0, 1.0, 1.0])
    end
    @testset "distances" begin
        g = named_grid((3, 3))
        @test eccentricity(g, (1, 1)) == 4
        @test eccentricities(g, [(1, 2), (2, 2)]) == [3, 2]
        @test eccentricities(g, Indices([(1, 2), (2, 2)])) ==
            Dictionary([(1, 2), (2, 2)], [3, 2])
        @test eccentricities(g) == Dictionary(vertices(g), [4, 3, 4, 3, 2, 3, 4, 3, 4])
        @test issetequal(center(g), [(2, 2)])
        @test radius(g) == 2
        @test diameter(g) == 4
        @test issetequal(periphery(g), [(1, 1), (3, 1), (1, 3), (3, 3)])
    end
    @testset "Bandwidth minimization" begin
        g₀ = NamedGraph(path_graph(5), ["A", "B", "C", "D", "E"])
        p = [3, 1, 5, 4, 2]
        g = permute_vertices(g₀, p)
        @test g == g₀

        gp = symrcm_permute(g)
        @test g == gp

        pp = symrcm_perm(g)
        @test pp == reverse(invperm(p))

        gp′ = permute_vertices(g, pp)
        @test g == gp′

        A = adjacency_matrix(gp)
        for i in 1:nv(g)
            for j in 1:nv(g)
                if abs(i - j) == 1
                    @test A[i, j] == A[j, i] == 1
                else
                    @test A[i, j] == 0
                end
            end
        end
    end
    @testset "boundary" begin
        g = named_grid((5, 5))
        subgraph_vertices = [
            (2, 2), (2, 3), (2, 4), (3, 2), (3, 3), (3, 4), (4, 2), (4, 3), (4, 4),
        ]
        inner_vertices = setdiff(subgraph_vertices, [(3, 3)])
        outer_vertices = setdiff(vertices(g), subgraph_vertices, periphery(g))
        @test issetequal(boundary_vertices(g, subgraph_vertices), inner_vertices)
        @test issetequal(inner_boundary_vertices(g, subgraph_vertices), inner_vertices)
        @test issetequal(outer_boundary_vertices(g, subgraph_vertices), outer_vertices)
        es = boundary_edges(g, subgraph_vertices)
        @test length(es) == 12
        @test eltype(es) <: NamedEdge
        for v1 in inner_vertices
            for v2 in outer_vertices
                if has_edge(g, v1 => v2)
                    @test edgetype(g)(v1, v2) ∈ es
                end
            end
        end
    end
    @testset "steiner_tree" begin
        g = named_grid((3, 5))
        terminal_vertices = [(1, 2), (1, 4), (3, 4)]
        st = steiner_tree(g, terminal_vertices)
        es = [(1, 2) => (1, 3), (1, 3) => (1, 4), (1, 4) => (2, 4), (2, 4) => (3, 4)]
        @test ne(st) == 4
        @test nv(st) == 5
        @test !any(v -> iszero(degree(st, v)), vertices(st))
        for e in es
            @test has_edge(st, e)
        end

        g = named_path_graph(4)
        terminal_vertices = [1, 3]
        st = steiner_tree(g, terminal_vertices)
        es = [1 => 2, 2 => 3]
        @test ne(st) == 2
        @test nv(st) == 3
        for e in es
            @test has_edge(st, e)
        end
    end
    @testset "topological_sort_by_dfs" begin
        g = NamedDiGraph(["A", "B", "C", "D", "E", "F", "G"])
        add_edge!(g, "A" => "D")
        add_edge!(g, "B" => "D")
        add_edge!(g, "B" => "E")
        add_edge!(g, "C" => "E")
        add_edge!(g, "D" => "F")
        add_edge!(g, "D" => "G")
        add_edge!(g, "E" => "G")
        t = topological_sort_by_dfs(g)
        for e in edges(g)
            @test findfirst(x -> x == src(e), t) < findfirst(x -> x == dst(e), t)
        end
    end
end
end
