using Graphs
using NamedGraphs
using NamedGraphs.Dictionaries
using Test

@testset "NamedEdge" begin
  @test is_ordered(NamedEdge("A", "B"))
  @test !is_ordered(NamedEdge("B", "A"))
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

    zg = zero(g)
    @test zg isa NamedGraph{String}
    @test nv(zg) == 0
    @test ne(zg) == 0

    @test degree(g, "A") == 1
    @test degree(g, "B") == 2

    add_vertex!(g, "E")
    @test has_vertex(g, "E")

    rem_vertex!(g, "E")
    @test !has_vertex(g, "E")

    io = IOBuffer()
    show(io, "text/plain", g)
    @test String(take!(io)) isa String

    add_edge!(g, "A" => "C")

    @test has_edge(g, "A" => "C")
    @test issetequal(neighbors(g, "A"), ["B", "C"])
    @test issetequal(neighbors(g, "B"), ["A", "C"])

    g_sub = g[["A", "B"]]

    @test has_vertex(g_sub, "A")
    @test has_vertex(g_sub, "B")
    @test !has_vertex(g_sub, "C")
    @test !has_vertex(g_sub, "D")

    g = NamedGraph(["A", "B", "C", "D", "E"])
    add_edge!(g, "A" => "B")
    add_edge!(g, "B" => "C")
    add_edge!(g, "D" => "E")
    @test has_path(g, "A", "B")
    @test has_path(g, "A", "C")
    @test has_path(g, "D", "E")
    @test !has_path(g, "A", "E")
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

    @test degrees(g) == [1, 2, 1, 0]
    @test degrees(g, ["B", "C"]) == [2, 1]
    @test degrees(g, Indices(["B", "C"])) == Dictionary(["B", "C"], [2, 1])
    @test indegrees(g) == [0, 1, 1, 0]
    @test outdegrees(g) == [1, 1, 0, 0]

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
    @test t isa NamedDiGraph{Tuple{Int,Int}}
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
    vertices_g = [
      (1, 1),
      (2, 1),
      (3, 1),
      (1, 2),
      (2, 2),
      (3, 2),
      (1, 3),
      (2, 3),
      (3, 3),
    ]
    parent_vertices = [
      (1, 1),
      (1, 1),
      (2, 1),
      (1, 1),
      (2, 1),
      (3, 1),
      (1, 2),
      (2, 2),
      (3, 2),
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
    @test t isa NamedDiGraph{Tuple{Int,Int}}
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
    vertices_g = [
      (1, 1),
      (2, 1),
      (3, 1),
      (1, 2),
      (2, 2),
      (3, 2),
      (1, 3),
      (2, 3),
      (3, 3),
    ]
    parent_vertices = [
      (1, 1),
      (1, 1),
      (2, 1),
      (2, 2),
      (3, 2),
      (3, 1),
      (1, 2),
      (1, 3),
      (2, 3),
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
    @test eltype(p) == NamedEdge{Tuple{Int,Int}}

    ps = spfa_shortest_paths(g, (1, 1))
    @test ps isa Dictionary{Tuple{Int,Int},Int}
    @test length(ps) == 100
    @test ps[(8, 1)] == 7

    es = boruvka_mst(g)
    @test length(es) == 99
    @test es isa Vector{NamedEdge{Tuple{Int,Int}}}

    es = kruskal_mst(g)
    @test length(es) == 99
    @test es isa Vector{NamedEdge{Tuple{Int,Int}}}

    es = prim_mst(g)
    @test length(es) == 99
    @test es isa Vector{NamedEdge{Tuple{Int,Int}}}

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
  @testset "has_self_loops" begin
    g = NamedGraph(2)
    @test g isa NamedGraph{Int}
    add_edge!(g, 1, 2)
    @test !has_self_loops(g)
    add_edge!(g, 1, 1)
    @test has_self_loops(g)
  end
  end
end
