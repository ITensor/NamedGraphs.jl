@eval module $(gensym())
using AbstractTrees:
  IndexNode,
  Leaves,
  PostOrderDFS,
  childindices,
  children,
  nodevalue,
  nodevalues,
  parent,
  parentindex,
  rootindex
using Dictionaries: Dictionary, Indices
using Graphs:
  add_edge!,
  edges,
  edgetype,
  inneighbors,
  is_cyclic,
  is_directed,
  ne,
  nv,
  outneighbors,
  rem_edge!,
  vertices
using Graphs.SimpleGraphs:
  SimpleDiGraph, SimpleEdge, SimpleGraph, grid, path_digraph, path_graph
using NamedGraphs: NamedGraph
using NamedGraphs.GraphsExtensions:
  TreeGraph,
  ⊔,
  add_edge,
  add_edges,
  add_edges!,
  all_edges,
  degrees,
  directed_graph,
  directed_graph_type,
  disjoint_union,
  indegrees,
  is_arborescence,
  is_ditree,
  is_path_graph,
  is_self_loop,
  outdegrees,
  permute_vertices,
  rem_edge,
  rem_edges,
  rem_edges!,
  rename_vertices,
  subgraph,
  tree_graph_node,
  undirected_graph,
  undirected_graph_type,
  vertextype
using Test: @test, @test_broken, @testset

@testset "NamedGraphs.GraphsExtensions" begin
  # is_self_loop
  @test is_self_loop(SimpleEdge(1, 1))
  @test !is_self_loop(SimpleEdge(1, 2))
  @test is_self_loop(1 => 1)
  @test !is_self_loop(1 => 2)

  # directed_graph_type
  @test directed_graph_type(SimpleGraph{Int}) === SimpleDiGraph{Int}
  @test directed_graph_type(SimpleGraph(4)) === SimpleDiGraph{Int}

  # undirected_graph_type
  @test undirected_graph_type(SimpleGraph{Int}) === SimpleGraph{Int}
  @test undirected_graph_type(SimpleGraph(4)) === SimpleGraph{Int}

  # directed_graph
  @test directed_graph(path_digraph(4)) == path_digraph(4)
  @test typeof(directed_graph(path_digraph(4))) === SimpleDiGraph{Int}
  g = path_graph(4)
  dig = directed_graph(g)
  @test typeof(dig) === SimpleDiGraph{Int}
  @test nv(dig) == 4
  @test ne(dig) == 6
  @test issetequal(
    edges(dig), edgetype(dig).([1 => 2, 2 => 1, 2 => 3, 3 => 2, 3 => 4, 4 => 3])
  )

  # undirected_graph
  @test undirected_graph(path_graph(4)) == path_graph(4)
  @test typeof(undirected_graph(path_graph(4))) === SimpleGraph{Int}
  dig = path_digraph(4)
  g = undirected_graph(dig)
  @test typeof(g) === SimpleGraph{Int}
  @test g == path_graph(4)

  # vertextype
  for f in (path_graph, path_digraph)
    for vtype in (Int, UInt64)
      @test vertextype(f(vtype(4))) === vtype
      @test vertextype(typeof(f(vtype(4)))) === vtype
    end
  end

  # rename_vertices
  vs = ["a", "b", "c", "d"]
  for g in (
    rename_vertices(v -> vs[v], path_graph(4)),
    rename_vertices(path_graph(4), Dict(eachindex(vs) .=> vs)),
  )
    @test nv(g) == 4
    @test ne(g) == 3
    @test issetequal(vertices(g), vs)
    @test issetequal(edges(g), edgetype(g).(["a" => "b", "b" => "c", "c" => "d"]))
    @test g isa NamedGraph
  end

  # permute_vertices
  g = path_graph(4)
  @test_broken permute_vertices(g, [2, 1, 4, 3])

  # all_edges
  g = path_graph(4)
  @test issetequal(
    all_edges(g), edgetype(g).([1 => 2, 2 => 1, 2 => 3, 3 => 2, 3 => 4, 4 => 3])
  )
  g = path_digraph(4)
  @test issetequal(all_edges(g), edgetype(g).([1 => 2, 2 => 3, 3 => 4]))

  # subgraph
  g = subgraph(path_graph(4), 2:4)
  @test nv(g) == 3
  @test ne(g) == 2
  # TODO: Should this preserve vertex names by
  # converting to `NamedGraph` if indexed by
  # something besides `Base.OneTo`?
  @test vertices(g) == 1:3
  @test issetequal(edges(g), edgetype(g).([1 => 2, 2 => 3]))
  @test subgraph(v -> v ∈ 2:4, path_graph(4)) == g

  # degrees
  @test degrees(path_graph(4)) == [1, 2, 2, 1]
  @test degrees(path_graph(4), 2:4) == [2, 2, 1]
  @test degrees(path_digraph(4)) == [1, 2, 2, 1]
  @test degrees(path_digraph(4), 2:4) == [2, 2, 1]
  @test degrees(path_graph(4), Indices(2:4)) == Dictionary(2:4, [2, 2, 1])

  # indegrees
  @test indegrees(path_graph(4)) == [1, 2, 2, 1]
  @test indegrees(path_graph(4), 2:4) == [2, 2, 1]
  @test indegrees(path_digraph(4)) == [0, 1, 1, 1]
  @test indegrees(path_digraph(4), 2:4) == [1, 1, 1]

  # outdegrees
  @test outdegrees(path_graph(4)) == [1, 2, 2, 1]
  @test outdegrees(path_graph(4), 2:4) == [2, 2, 1]
  @test outdegrees(path_digraph(4)) == [1, 1, 1, 0]
  @test outdegrees(path_digraph(4), 2:4) == [1, 1, 0]

  # TreeGraph
  # Binary tree:
  #       
  #      7
  #     / \
  #    /   \
  #   5     6
  #  / \   / \
  # 1   2 3   4
  #
  # with vertex 6 as root.
  g = SimpleDiGraph(7)
  add_edge!(g, 5 => 1)
  add_edge!(g, 5 => 2)
  add_edge!(g, 7 => 5)
  add_edge!(g, 6 => 7)
  add_edge!(g, 6 => 3)
  add_edge!(g, 6 => 4)
  @test is_arborescence(g)
  @test is_ditree(g)
  g′ = copy(g)
  add_edge!(g′, 5 => 6)
  @test !is_arborescence(g′)
  @test !is_ditree(g′)
  t = TreeGraph(g)
  @test is_directed(t)
  @test ne(t) == 6
  @test nv(t) == 7
  @test vertices(t) == 1:7
  @test issetequal(outneighbors(t, 6), [3, 4, 7])
  @test isempty(inneighbors(t, 6))
  @test only(inneighbors(t, 5)) == 7
  @test edgetype(t) == SimpleEdge{Int}
  @test vertextype(t) == Int
  @test tree_graph_node(g, 5) == IndexNode(t, 5)
  @test rootindex(t) == 6
  @test issetequal(childindices(t, 6), [3, 4, 7])
  @test issetequal(childindices(t, 7), [5])
  @test isempty(childindices(t, 2))
  @test isnothing(parentindex(t, 6))
  @test parentindex(t, 3) == 6
  @test parentindex(t, 5) == 7
  @test IndexNode(t) == IndexNode(t, 6)
  @test tree_graph_node(g) == tree_graph_node(g, 6)
  dfs_g = collect(nodevalues(PostOrderDFS(tree_graph_node(g, 6))))
  @test length(dfs_g) == 7
  @test issetequal(dfs_g[1:4], 1:4)
  @test dfs_g[5:7] == [5, 7, 6]
  @test issetequal(nodevalue.(children(tree_graph_node(g, 5))), 1:2)
  @test isempty(children(tree_graph_node(g, 1)))
  @test issetequal(nodevalue.(Leaves(tree_graph_node(g))), 1:4)
  @test nodevalue(parent(tree_graph_node(g, 5))) == 7

  # disjoint_union, ⊔
  g1 = path_graph(3)
  g2 = path_graph(3)
  for g in (
    disjoint_union(g1, g2),
    disjoint_union([g1, g2]),
    disjoint_union([1 => g1, 2 => g2]),
    disjoint_union(Dictionary([1, 2], [g1, g2])),
    g1 ⊔ g2,
    (1 => g1) ⊔ (2 => g2),
  )
    @test nv(g) == 6
    @test ne(g) == 4
    @test issetequal(vertices(g), [(1, 1), (2, 1), (3, 1), (1, 2), (2, 2), (3, 2)])
  end
  for g in (
    disjoint_union("x" => g1, "y" => g2),
    disjoint_union(["x" => g1, "y" => g2]),
    disjoint_union(Dictionary(["x", "y"], [g1, g2])),
    ("x" => g1) ⊔ ("y" => g2),
  )
    @test nv(g) == 6
    @test ne(g) == 4
    @test issetequal(
      vertices(g), [(1, "x"), (2, "x"), (3, "x"), (1, "y"), (2, "y"), (3, "y")]
    )
  end

  # is_path_graph
  g = path_graph(4)
  @test is_path_graph(g)
  g = grid((3, 2))
  @test !is_path_graph(g)

  # TODO:
  # - is_leaf_vertex
  # - is_root_vertex
  # - is_rooted
  # - root_vertex
  # - parent_vertex

  # add_edge
  g = SimpleGraph(4)
  add_edge!(g, 1 => 2)
  @test add_edge(SimpleGraph(4), 1 => 2) == g

  # add_edges
  @test add_edges(SimpleGraph(4), [1 => 2, 2 => 3, 3 => 4]) == path_graph(4)

  # add_edges!
  g = SimpleGraph(4)
  add_edges!(g, [1 => 2, 2 => 3, 3 => 4])
  @test g == path_graph(4)

  # rem_edge
  g = path_graph(4)
  # https://github.com/JuliaGraphs/Graphs.jl/issues/364
  rem_edge!(g, 2, 3)
  @test rem_edge(path_graph(4), 2 => 3) == g

  # rem_edges
  g = path_graph(4)
  # https://github.com/JuliaGraphs/Graphs.jl/issues/364
  rem_edge!(g, 2, 3)
  rem_edge!(g, 3, 4)
  @test rem_edges(path_graph(4), [2 => 3, 3 => 4]) == g

  # rem_edges!
  g = path_graph(4)
  # https://github.com/JuliaGraphs/Graphs.jl/issues/364
  rem_edge!(g, 2, 3)
  rem_edge!(g, 3, 4)
  g′ = path_graph(4)
  rem_edges!(g′, [2 => 3, 3 => 4])
  @test g′ == g
end
end
