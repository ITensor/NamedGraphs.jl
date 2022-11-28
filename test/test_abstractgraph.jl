using Test
using Graphs
using NamedGraphs

@testset "Tree graph paths" begin
  # undirected trees
  g1 = comb_tree((3, 2))
  et1 = edgetype(g1)
  @test vertex_path(g1, 4, 5) == [4, 1, 2, 5]
  @test edge_path(g1, 4, 5) == [et1(4, 1), et1(1, 2), et1(2, 5)]
  @test vertex_path(g1, 6, 1) == [6, 3, 2, 1]
  @test edge_path(g1, 6, 1) == [et1(6, 3), et1(3, 2), et1(2, 1)]
  @test vertex_path(g1, 2, 2) == [2]
  @test edge_path(g1, 2, 2) == et1[]

  ng1 = named_comb_tree((3, 2))
  net1 = edgetype(ng1)
  @test vertex_path(ng1, (1, 2), (2, 2)) == [(1, 2), (1, 1), (2, 1), (2, 2)]
  @test edge_path(ng1, (1, 2), (2, 2)) ==
    [net1((1, 2), (1, 1)), net1((1, 1), (2, 1)), net1((2, 1), (2, 2))]
  @test vertex_path(ng1, (3, 2), (1, 1)) == [(3, 2), (3, 1), (2, 1), (1, 1)]
  @test edge_path(ng1, (3, 2), (1, 1)) ==
    [net1((3, 2), (3, 1)), net1((3, 1), (2, 1)), net1((2, 1), (1, 1))]
  @test vertex_path(ng1, (1, 2), (1, 2)) == [(1, 2)]
  @test edge_path(ng1, (1, 2), (1, 2)) == net1[]

  g2 = binary_tree(3)
  et2 = edgetype(g2)
  @test vertex_path(g2, 2, 6) == [2, 1, 3, 6]
  @test edge_path(g2, 2, 6) == [et2(2, 1), et2(1, 3), et2(3, 6)]
  @test vertex_path(g2, 5, 4) == [5, 2, 4]
  @test edge_path(g2, 5, 4) == [et2(5, 2), et2(2, 4)]

  ng2 = named_binary_tree(3)
  net2 = edgetype(ng2)
  @test vertex_path(ng2, (1, 1), (1, 2, 1)) == [(1, 1), (1,), (1, 2), (1, 2, 1)]
  @test edge_path(ng2, (1, 1), (1, 2, 1)) ==
    [net2((1, 1), (1,)), net2((1,), (1, 2)), net2((1, 2), (1, 2, 1))]
  @test vertex_path(ng2, (1, 1, 2), (1, 1, 1)) == [(1, 1, 2), (1, 1), (1, 1, 1)]
  @test edge_path(ng2, (1, 1, 2), (1, 1, 1)) ==
    [net2((1, 1, 2), (1, 1)), net2((1, 1), (1, 1, 1))]

  # directed trees
  dg1 = dfs_tree(g1, 5)
  # same behavior if path exists
  @test vertex_path(dg1, 4, 5) == [4, 1, 2, 5]
  @test edge_path(dg1, 4, 5) == [et1(4, 1), et1(1, 2), et1(2, 5)]
  # returns nothing if path does not exists
  @test isnothing(vertex_path(dg1, 4, 6))
  @test isnothing(edge_path(dg1, 4, 6))

  dng1 = dfs_tree(ng1, (2, 2))
  @test vertex_path(dng1, (1, 2), (2, 2)) == [(1, 2), (1, 1), (2, 1), (2, 2)]
  @test edge_path(dng1, (1, 2), (2, 2)) ==
    [net1((1, 2), (1, 1)), net1((1, 1), (2, 1)), net1((2, 1), (2, 2))]
  @test isnothing(vertex_path(dng1, (1, 2), (3, 2)))
  @test isnothing(edge_path(dng1, (1, 2), (3, 2)))
end

@testset "Tree graph leaf vertices" begin
  # undirected trees
  g = comb_tree((3, 2))
  @test is_leaf(g, 4)
  @test !is_leaf(g, 1)
  @test issetequal(leaf_vertices(g), [4, 5, 6])

  ng = named_comb_tree((3, 2))
  @test is_leaf(ng, (1, 2))
  @test is_leaf(ng, (2, 2))
  @test !is_leaf(ng, (1, 1))
  @test issetequal(leaf_vertices(ng), [(1, 2), (2, 2), (3, 2)])

  # directed trees
  dng = dfs_tree(ng, (2, 2))
  @test is_leaf(dng, (1, 2))
  @test !is_leaf(dng, (2, 2))
  @test !is_leaf(dng, (1, 1))
  @test issetequal(leaf_vertices(dng), [(1, 2), (3, 2)])
end
