using Test
using NamedGraphs
using NamedGraphs:
  spanning_forest,
  spanning_tree,
  forest_cover,
  PartitionEdge,
  PartitionVertex,
  parent,
  default_root_vertex,
  triangular_lattice_graph,
  add_edges!
using Dictionaries
using Graphs

@testset "Test Partitioned Graph Constructors" begin
  nx, ny = 10, 10
  g = named_grid((nx, ny))

  partitions = [[(i, j) for j in 1:ny] for i in 1:nx]
  pg = PartitionedGraph(g, partitions)
  @test vertextype(partitioned_graph(pg)) == Int64
  @test vertextype(unpartitioned_graph(pg)) == vertextype(g)
  @test is_tree(partitioned_graph(pg))
  @test nv(pg) == nx * ny
  @test nv(partitioned_graph(pg)) == nx

  partition_dict = Dictionary([first(partition) for partition in partitions], partitions)
  pg = PartitionedGraph(g, partition_dict)
  @test vertextype(partitioned_graph(pg)) == vertextype(g)
  @test vertextype(unpartitioned_graph(pg)) == vertextype(g)
  @test is_tree(partitioned_graph(pg))
  @test nv(pg) == nx * ny
  @test nv(partitioned_graph(pg)) == nx

  pg = PartitionedGraph([i for i in 1:nx])
  @test unpartitioned_graph(pg) == partitioned_graph(pg)
  @test nv(pg) == nx
  @test nv(partitioned_graph(pg)) == nx
  @test ne(pg) == 0
  @test ne(partitioned_graph(pg)) == 0
end

@testset "Test Partitioned Graph Vertex/Edge Addition and Removal" begin
  nx, ny = 10, 10
  g = named_grid((nx, ny))

  partitions = [[(i, j) for j in 1:ny] for i in 1:nx]
  pg = PartitionedGraph(g, partitions)

  pv = PartitionVertex(5)
  v_set = vertices(pg, pv)
  edges_involving_v_set = boundary_edges(g, v_set)

  #Strip the middle column from pg via the partitioned graph vertex, and make a new pg
  rem_vertex!(pg, pv)
  @test !is_connected(unpartitioned_graph(pg)) && !is_connected(partitioned_graph(pg))
  @test parent(pv) ∉ vertices(partitioned_graph(pg))
  @test !has_vertex(pg, pv)
  @test nv(pg) == (nx - 1) * ny
  @test nv(partitioned_graph(pg)) == nx - 1
  @test !is_tree(partitioned_graph(pg))

  #Add the column back to the in place graph
  add_vertices!(pg, v_set, pv)
  add_edges!(pg, edges_involving_v_set)
  @test is_connected(pg.graph) && is_path_graph(partitioned_graph(pg))
  @test parent(pv) ∈ vertices(partitioned_graph(pg))
  @test has_vertex(pg, pv)
  @test is_tree(partitioned_graph(pg))
  @test nv(pg) == nx * ny
  @test nv(partitioned_graph(pg)) == nx
end

@testset "Test Partitioned Graph Subgraph Functionality" begin
  n, z = 12, 4
  g = NamedGraph(random_regular_graph(n, z))
  partitions = dictionary([
    1 => [1, 2, 3], 2 => [4, 5, 6], 3 => [7, 8, 9], 4 => [10, 11, 12]
  ])
  pg = PartitionedGraph(g, partitions)

  subgraph_partitioned_vertices = [1, 2]
  subgraph_vertices = reduce(
    vcat, [partitions[spv] for spv in subgraph_partitioned_vertices]
  )

  pg_1 = subgraph(pg, PartitionVertex.(subgraph_partitioned_vertices))
  pg_2 = subgraph(pg, subgraph_vertices)
  @test pg_1 == pg_2
  @test nv(pg_1) == length(subgraph_vertices)
  @test nv(partitioned_graph(pg_1)) == length(subgraph_partitioned_vertices)

  subgraph_partitioned_vertex = 3
  subgraph_vertices = partitions[subgraph_partitioned_vertex]
  g_1 = subgraph(pg, PartitionVertex(subgraph_partitioned_vertex))
  pg_1 = subgraph(pg, subgraph_vertices)
  @test unpartitioned_graph(pg_1) == subgraph(g, subgraph_vertices)
  @test g_1 == subgraph(g, subgraph_vertices)
end

@testset "Test NamedGraphs Functions on Partitioned Graph" begin
  functions = [is_tree, default_root_vertex, center, diameter, radius]
  gs = [
    named_comb_tree((4, 4)),
    named_grid((2, 2, 2)),
    NamedGraph(random_regular_graph(12, 3)),
    triangular_lattice_graph(7, 7),
  ]

  for f in functions
    for g in gs
      pg = PartitionedGraph(g, [vertices(g)])
      @test f(pg) == f(unpartitioned_graph(pg))
      @test nv(pg) == nv(g)
      @test nv(partitioned_graph(pg)) == 1
      @test ne(pg) == ne(g)
      @test ne(partitioned_graph(pg)) == 0
    end
  end
end
