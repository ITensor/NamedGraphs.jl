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
  add_vertex!,
  dst,
  edges,
  edgetype,
  has_edge,
  inneighbors,
  is_cyclic,
  is_directed,
  ne,
  nv,
  outneighbors,
  rem_edge!,
  src,
  vertices
using Graphs.SimpleGraphs:
  SimpleDiGraph,
  SimpleEdge,
  SimpleGraph,
  binary_tree,
  cycle_digraph,
  cycle_graph,
  grid,
  path_digraph,
  path_graph
using NamedGraphs: NamedDiGraph, NamedEdge, NamedGraph
using NamedGraphs.GraphGenerators: binary_arborescence
using NamedGraphs.GraphsExtensions:
  TreeGraph,
  ⊔,
  add_edge,
  add_edges,
  add_edges!,
  all_edges,
  arrange_edge,
  arranged_edges,
  child_edges,
  child_vertices,
  convert_vertextype,
  degrees,
  directed_graph,
  directed_graph_type,
  disjoint_union,
  distance_to_leaves,
  has_edges,
  has_leaf_neighbor,
  has_vertices,
  incident_edges,
  indegrees,
  is_arborescence,
  is_arranged,
  is_binary_arborescence,
  is_cycle_graph,
  is_ditree,
  is_edge_arranged,
  is_leaf_edge,
  is_leaf_vertex,
  is_path_graph,
  is_root_vertex,
  is_rooted,
  is_self_loop,
  leaf_vertices,
  minimum_distance_to_leaves,
  next_nearest_neighbors,
  non_leaf_edges,
  outdegrees,
  permute_vertices,
  rem_edge,
  rem_edges,
  rem_edges!,
  rename_vertices,
  root_vertex,
  subgraph,
  tree_graph_node,
  undirected_graph,
  undirected_graph_type,
  vertextype,
  vertices_at_distance
using Test: @test, @test_broken, @test_throws, @testset

# TODO: Still need to test:
# - post_order_dfs_vertices
# - pre_order_dfs_vertices
# - post_order_dfs_edges
# - vertex_path
# - edge_path
# - parent_vertices
# - parent_vertex
# - parent_edges
# - parent_edge
# - mincut_partitions
# - eccentricities
# - decorate_graph_edges
# - decorate_graph_vertices
# - random_bfs_tree

@testset "NamedGraphs.GraphsExtensions" begin
  # has_vertices
  g = path_graph(4)
  @test has_vertices(g, 1:3)
  @test has_vertices(g, [2, 4])
  @test !has_vertices(g, [2, 5])

  # has_edges
  g = path_graph(4)
  @test has_edges(g, [1 => 2, 2 => 3, 3 => 4])
  @test has_edges(g, [2 => 3])
  @test !has_edges(g, [1 => 3])
  @test !has_edges(g, [4 => 5])

  # convert_vertextype
  for g in (path_graph(4), path_digraph(4))
    g_uint16 = convert_vertextype(UInt16, g)
    @test g_uint16 == g
    @test vertextype(g_uint16) == UInt16
    @test issetequal(vertices(g_uint16), vertices(g))
    @test issetequal(edges(g_uint16), edges(g))
  end

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
  g = rename_vertices(v -> vs[v], NamedGraph(path_graph(4)))
  @test nv(g) == 4
  @test ne(g) == 3
  @test issetequal(vertices(g), vs)
  @test issetequal(edges(g), edgetype(g).(["a" => "b", "b" => "c", "c" => "d"]))
  @test g isa NamedGraph
  # Not defined for AbstractSimpleGraph.
  @test_throws ErrorException rename_vertices(v -> vs[v], path_graph(4))

  # permute_vertices
  g = path_graph(4)
  g_perm = permute_vertices(g, [2, 1, 4, 3])
  @test nv(g_perm) == 4
  @test ne(g_perm) == 3
  @test vertices(g_perm) == 1:4
  @test has_edge(g_perm, 1 => 2)
  @test has_edge(g_perm, 2 => 1)
  @test has_edge(g_perm, 1 => 4)
  @test has_edge(g_perm, 4 => 1)
  @test has_edge(g_perm, 3 => 4)
  @test has_edge(g_perm, 4 => 3)
  @test !has_edge(g_perm, 2 => 3)
  @test !has_edge(g_perm, 3 => 2)
  g = path_digraph(4)
  g_perm = permute_vertices(g, [2, 1, 4, 3])
  @test nv(g_perm) == 4
  @test ne(g_perm) == 3
  @test vertices(g_perm) == 1:4
  @test has_edge(g_perm, 2 => 1)
  @test !has_edge(g_perm, 1 => 2)
  @test has_edge(g_perm, 1 => 4)
  @test !has_edge(g_perm, 4 => 1)
  @test has_edge(g_perm, 4 => 3)
  @test !has_edge(g_perm, 3 => 4)

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
  #      1
  #     / \
  #    /   \
  #   2     3
  #  / \   / \
  # 4   5 6   7
  #
  # with vertex 1 as root.
  g = binary_arborescence(3)
  @test is_arborescence(g)
  @test is_binary_arborescence(g)
  @test is_ditree(g)
  g′ = copy(g)
  add_edge!(g′, 2 => 3)
  @test !is_arborescence(g′)
  @test !is_ditree(g′)
  t = TreeGraph(g)
  @test is_directed(t)
  @test ne(t) == 6
  @test nv(t) == 7
  @test vertices(t) == 1:7
  @test issetequal(outneighbors(t, 1), [2, 3])
  @test issetequal(outneighbors(t, 2), [4, 5])
  @test issetequal(outneighbors(t, 3), [6, 7])
  @test isempty(inneighbors(t, 1))
  for v in 2:3
    @test only(inneighbors(t, v)) == 1
  end
  for v in 4:5
    @test only(inneighbors(t, v)) == 2
  end
  for v in 6:7
    @test only(inneighbors(t, v)) == 3
  end
  @test edgetype(t) === SimpleEdge{Int}
  @test vertextype(t) == Int
  @test nodevalue(t) == 1
  for v in 1:7
    @test tree_graph_node(g, v) == IndexNode(t, v)
  end
  @test rootindex(t) == 1
  @test issetequal(nodevalue.(children(t)), 2:3)
  @test issetequal(childindices(t, 1), 2:3)
  @test issetequal(childindices(t, 2), 4:5)
  @test issetequal(childindices(t, 3), 6:7)
  for v in 4:7
    @test isempty(childindices(t, v))
  end
  @test isnothing(parentindex(t, 1))
  for v in 2:3
    @test parentindex(t, v) == 1
  end
  for v in 4:5
    @test parentindex(t, v) == 2
  end
  for v in 6:7
    @test parentindex(t, v) == 3
  end
  @test IndexNode(t) == IndexNode(t, 1)
  @test tree_graph_node(g) == tree_graph_node(g, 1)
  for dfs_g in (
    collect(nodevalues(PostOrderDFS(tree_graph_node(g, 1)))),
    collect(nodevalues(PostOrderDFS(t))),
  )
    @test length(dfs_g) == 7
    @test dfs_g == [4, 5, 2, 6, 7, 3, 1]
  end
  @test issetequal(nodevalue.(children(tree_graph_node(g, 1))), 2:3)
  @test issetequal(nodevalue.(children(tree_graph_node(g, 2))), 4:5)
  @test issetequal(nodevalue.(children(tree_graph_node(g, 3))), 6:7)
  for v in 4:7
    @test isempty(children(tree_graph_node(g, v)))
  end
  for n in (tree_graph_node(g), t)
    @test issetequal(nodevalue.(Leaves(n)), 4:7)
  end
  @test issetequal(nodevalue.(Leaves(t)), 4:7)
  @test isnothing(nodevalue(parent(tree_graph_node(g, 1))))
  for v in 2:3
    @test nodevalue(parent(tree_graph_node(g, v))) == 1
  end
  for v in 4:5
    @test nodevalue(parent(tree_graph_node(g, v))) == 2
  end
  for v in 6:7
    @test nodevalue(parent(tree_graph_node(g, v))) == 3
  end

  # disjoint_union, ⊔
  g1 = NamedGraph(path_graph(3))
  g2 = NamedGraph(path_graph(3))
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
  @test is_path_graph(path_graph(4))
  @test !is_path_graph(cycle_graph(4))
  # Only defined for undirected graphs at the moment.
  @test_throws MethodError is_path_graph(path_digraph(4))
  @test !is_path_graph(grid((3, 2)))

  # is_cycle_graph
  @test is_cycle_graph(cycle_graph(4))
  @test !is_cycle_graph(path_graph(4))
  # Only defined for undirected graphs at the moment.
  @test_throws MethodError is_cycle_graph(cycle_digraph(4))
  @test !is_cycle_graph(grid((3, 2)))
  @test is_cycle_graph(grid((2, 2)))

  # incident_edges
  g = path_graph(4)
  @test issetequal(incident_edges(g, 2), SimpleEdge.([2 => 1, 2 => 3]))
  @test issetequal(incident_edges(g, 2; dir=:out), SimpleEdge.([2 => 1, 2 => 3]))
  @test issetequal(incident_edges(g, 2; dir=:in), SimpleEdge.([1 => 2, 3 => 2]))
  # TODO: Only output out edges?
  @test issetequal(
    incident_edges(g, 2; dir=:both), SimpleEdge.([2 => 1, 1 => 2, 2 => 3, 3 => 2])
  )

  # is_leaf_vertex
  g = binary_tree(3)
  for v in 1:3
    @test !is_leaf_vertex(g, v)
  end
  for v in 4:7
    @test is_leaf_vertex(g, v)
  end
  g = binary_arborescence(3)
  for v in 1:3
    @test !is_leaf_vertex(g, v)
  end
  for v in 4:7
    @test is_leaf_vertex(g, v)
  end

  # child_vertices
  g = binary_arborescence(3)
  @test issetequal(child_vertices(g, 1), 2:3)
  @test issetequal(child_vertices(g, 2), 4:5)
  @test issetequal(child_vertices(g, 3), 6:7)
  for v in 4:7
    @test isempty(child_vertices(g, v))
  end

  # child_edges
  g = binary_arborescence(3)
  @test issetequal(child_edges(g, 1), SimpleEdge.([1 => 2, 1 => 3]))
  @test issetequal(child_edges(g, 2), SimpleEdge.([2 => 4, 2 => 5]))
  @test issetequal(child_edges(g, 3), SimpleEdge.([3 => 6, 3 => 7]))
  for v in 4:7
    @test isempty(child_edges(g, v))
  end

  # leaf_vertices
  g = binary_tree(3)
  @test issetequal(leaf_vertices(g), 4:7)
  g = binary_arborescence(3)
  @test issetequal(leaf_vertices(g), 4:7)

  # is_leaf_edge
  g = binary_tree(3)
  for e in [1 => 2, 1 => 3]
    @test !is_leaf_edge(g, e)
    @test !is_leaf_edge(g, reverse(e))
  end
  for e in [2 => 4, 2 => 5, 3 => 6, 3 => 7]
    @test is_leaf_edge(g, e)
    @test is_leaf_edge(g, reverse(e))
  end
  g = binary_arborescence(3)
  for e in [1 => 2, 1 => 3]
    @test !is_leaf_edge(g, e)
    @test !is_leaf_edge(g, reverse(e))
  end
  for e in [2 => 4, 2 => 5, 3 => 6, 3 => 7]
    @test is_leaf_edge(g, e)
    @test !is_leaf_edge(g, reverse(e))
  end

  # has_leaf_neighbor
  for g in (binary_tree(3), binary_arborescence(3))
    for v in [1; 4:7]
      @test !has_leaf_neighbor(g, v)
    end
    for v in 2:3
      @test has_leaf_neighbor(g, v)
    end
  end

  # non_leaf_edges
  g = binary_tree(3)
  es = collect(non_leaf_edges(g))
  es = [es; reverse.(es)]
  for e in SimpleEdge.([1 => 2, 1 => 3])
    @test e in es
    @test reverse(e) in es
  end
  for e in SimpleEdge.([2 => 4, 2 => 5, 3 => 6, 3 => 7])
    @test !(e in es)
    @test !(reverse(e) in es)
  end
  g = binary_arborescence(3)
  es = collect(non_leaf_edges(g))
  for e in SimpleEdge.([1 => 2, 1 => 3])
    @test e in es
    @test !(reverse(e) in es)
  end
  for e in SimpleEdge.([2 => 4, 2 => 5, 3 => 6, 3 => 7])
    @test !(e in es)
    @test !(reverse(e) in es)
  end

  # distance_to_leaves
  g = binary_tree(3)
  d = distance_to_leaves(g, 3)
  d_ref = Dict([4 => 3, 5 => 3, 6 => 1, 7 => 1])
  for v in keys(d)
    @test is_leaf_vertex(g, v)
    @test d[v] == d_ref[v]
  end
  g = binary_arborescence(3)
  d = distance_to_leaves(g, 3)
  d_ref = Dict([4 => typemax(Int), 5 => typemax(Int), 6 => 1, 7 => 1])
  for v in keys(d)
    @test is_leaf_vertex(g, v)
    @test d[v] == d_ref[v]
  end
  d = distance_to_leaves(g, 1)
  d_ref = Dict([4 => 2, 5 => 2, 6 => 2, 7 => 2])
  for v in keys(d)
    @test is_leaf_vertex(g, v)
    @test d[v] == d_ref[v]
  end

  # minimum_distance_to_leaves
  for g in (binary_tree(3), binary_arborescence(3))
    @test minimum_distance_to_leaves(g, 1) == 2
    @test minimum_distance_to_leaves(g, 3) == 1
    @test minimum_distance_to_leaves(g, 7) == 0
  end

  # is_root_vertex
  g = binary_arborescence(3)
  @test is_root_vertex(g, 1)
  for v in 2:7
    @test !is_root_vertex(g, v)
  end
  g = binary_tree(3)
  for v in vertices(g)
    @test_throws MethodError is_root_vertex(g, v)
  end

  # is_rooted
  @test is_rooted(binary_arborescence(3))
  g = binary_arborescence(3)
  add_edge!(g, 2 => 3)
  @test is_rooted(g)
  g = binary_arborescence(3)
  add_vertex!(g)
  add_edge!(g, 8 => 3)
  @test !is_rooted(g)
  @test is_rooted(path_digraph(4))
  @test_throws MethodError is_rooted(binary_tree(3))

  # is_binary_arborescence
  @test is_binary_arborescence(binary_arborescence(3))
  g = binary_arborescence(3)
  add_vertex!(g)
  add_edge!(g, 3 => 8)
  @test !is_binary_arborescence(g)
  @test_throws MethodError is_binary_arborescence(binary_tree(3))

  # root_vertex
  @test root_vertex(binary_arborescence(3)) == 1
  # No root vertex of cyclic graph.
  g = binary_arborescence(3)
  add_edge!(g, 7 => 1)
  @test_throws ErrorException root_vertex(g)
  @test_throws MethodError root_vertex(binary_tree(3))

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

  #vertices at distance
  L = 10
  g = path_graph(L)
  @test only(vertices_at_distance(g, 1, L - 1)) == L
  @test only(next_nearest_neighbors(g, 1)) == 3
  @test issetequal(vertices_at_distance(g, 5, 3), [2, 8])

  @testset "arrange" begin
    @testset "is_arranged, is_edge_arranged" begin
      for (a, b) in [
        (1, 2),
        ([1], [2]),
        ([1, 2], [2, 1]),
        ([1, 2], [2]),
        ([2], [2, 1]),
        ((1,), (2,)),
        ((1, 2), (2, 1)),
        ((1, 2), (2,)),
        ((2,), (2, 1)),
        ("X", 1),
        (("X",), (1, 2)),
      ]
        @test is_arranged(a, b)
        @test !is_arranged(b, a)
        @test is_edge_arranged(NamedEdge(a, b))
        @test !is_edge_arranged(NamedEdge(b, a))
        @test arrange_edge(NamedEdge(a, b)) == NamedEdge(a, b)
        @test arrange_edge(NamedEdge(b, a)) == NamedEdge(a, b)
        g = NamedGraph()
        @test is_edge_arranged(g, NamedEdge(a, b))
        @test !is_edge_arranged(g, NamedEdge(b, a))
        @test arrange_edge(g, NamedEdge(a, b)) == NamedEdge(a, b)
        @test arrange_edge(g, NamedEdge(b, a)) == NamedEdge(a, b)
        dig = NamedDiGraph()
        @test is_edge_arranged(dig, NamedEdge(a, b))
        @test is_edge_arranged(dig, NamedEdge(b, a))
        @test arrange_edge(dig, NamedEdge(a, b)) == NamedEdge(a, b)
        @test arrange_edge(dig, NamedEdge(b, a)) == NamedEdge(b, a)
      end
    end
    @testset "arranged_edges" begin
      vs = [1, 2, 3, 4]
      es = [1 => 2, 2 => 3, 3 => 4]
      # For undirected graphs, the edge ordering is based on the vertex ordering.
      g = NamedGraph(reverse(vs))
      add_edges!(g, es)
      @test all(!is_edge_arranged, edges(g))
      @test issetequal(arranged_edges(g), reverse.(edges(g)))

      vs = [1, 2, 3, 4]
      es = [2 => 1, 3 => 2, 4 => 3]
      dig = NamedDiGraph(reverse(vs))
      add_edges!(dig, es)
      @test all(!is_edge_arranged, edges(dig))
      @test issetequal(arranged_edges(dig), edges(dig))
    end
  end
end
