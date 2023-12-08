using Test
using NamedGraphs
using NamedGraphs:
  spanning_forest,
  subvertices,
  spanning_tree,
  forest_cover,
  rem_edge!,
  PartitionEdge,
  rem_edges!,
  underlying_vertex
using Dictionaries
using Graphs

@testset "Test Partition Constructors" begin
  nx, ny = 10, 10
  g = named_grid((nx, ny))

  partitions = [[(i, j) for j in 1:ny] for i in 1:nx]
  pg = PartitionedGraph(g, partitions)
  @test vertextype(pg.partitioned_graph) == Int64
  @test vertextype(pg.graph) == vertextype(g)

  partition_dict = Dictionary([first(partition) for partition in partitions], partitions)
  pg = PartitionedGraph(g, partition_dict)
  @test vertextype(pg.partitioned_graph) == vertextype(g)
  @test vertextype(pg.graph) == vertextype(g)

  pg = PartitionedGraph([i for i in 1:nx])
  @test pg.graph == pg.partitioned_graph
end

@testset "Test Partition Addition and Removal" begin
  nx, ny = 10, 10
  g = named_grid((nx, ny))

  partitions = [[(i, j) for j in 1:ny] for i in 1:nx]
  pg = PartitionedGraph(g, partitions)

  pv = 5
  v_set = pg.partition_vertices[pv]
  edges_involving_v_set = filter(
    e -> !isempty(intersect(v_set, [src(e), dst(e)])), edges(pg)
  )

  #Strip the middle column from pg
  NamedGraphs.rem_vertices!(pg, v_set)
  @test !is_connected(pg.graph) && !is_connected(pg.partitioned_graph)
  @test !haskey(pg.partition_vertices, pv)
  @test !has_vertex(pg, PartitionVertex(pv))

  #Add the column back
  NamedGraphs.add_vertices!(pg, v_set, pv)
  NamedGraphs.add_edges!(pg, edges_involving_v_set)
  @test is_connected(pg.graph) && is_path_graph(pg.partitioned_graph)
  @test haskey(pg.partition_vertices, pv)
  @test has_vertex(pg, PartitionVertex(pv))
end

@testset "Test NamedGraphs Functions on Partitioned Graph" begin
  functions = [is_tree, NamedGraphs.default_root_vertex, spanning_tree, spanning_forest]
  gs = [
    named_comb_tree((4, 4)),
    named_grid((2, 2, 2)),
    NamedGraph(random_regular_graph(12, 3)),
    NamedGraphs.triangular_lattice_graph(7, 7),
  ]

  for f in functions
    for g in gs
      pg = PartitionedGraph(g, [vertices(g)])
      @test f(pg) == f(pg.graph)
    end
  end
end
