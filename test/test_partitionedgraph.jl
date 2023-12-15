using Test
using NamedGraphs:
  spanning_forest,
  subvertices,
  spanning_tree,
  forest_cover,
  rem_edge!,
  PartitionEdge,
  rem_edges!,
  PartitionVertex,
  parent,
  _npartitions
using Dictionaries
using Graphs

@testset "Test Partitioned Graph Constructors" begin
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

@testset "Test Partitioned Graph Vertex/Edge Addition and Removal" begin
  nx, ny = 10, 10
  g = named_grid((nx, ny))

  partitions = [[(i, j) for j in 1:ny] for i in 1:nx]
  pg = PartitionedGraph(g, partitions)

  pv = PartitionVertex(5)
  v_set = vertices(pg, pv)
  edges_involving_v_set = filter(
    e -> !isempty(intersect(v_set, [src(e), dst(e)])), edges(pg)
  )

  #Strip the middle column from pg via the partitioned graph vertex, and make a new pg
  pg_stripped = NamedGraphs.rem_vertex(pg, pv)
  @test !is_connected(pg_stripped.graph) && !is_connected(pg_stripped.partitioned_graph)
  @test !haskey(pg_stripped.partitioned_vertices, parent(pv))
  @test !has_vertex(pg_stripped, pv)

  #Strip the middle column from pg directly and via the graph vertices, do it in place
  NamedGraphs.rem_vertices!(pg, v_set)
  @test !is_connected(pg.graph) && !is_connected(pg.partitioned_graph)
  @test !haskey(pg.partitioned_vertices, parent(pv))
  @test !has_vertex(pg, pv)

  #Test both are the same
  @test pg == pg_stripped

  #Add the column back to the in place graph
  NamedGraphs.add_vertices!(pg, v_set, pv)
  NamedGraphs.add_edges!(pg, edges_involving_v_set)
  @test is_connected(pg.graph) && is_path_graph(pg.partitioned_graph)
  @test haskey(pg.partitioned_vertices, parent(pv))
  @test has_vertex(pg, pv)
end

@testset "Test Partitioned Graph Subgraph Functionality" begin
  n, z = 20, 4
  nvertices_per_partition = 4
  g = NamedGraph(random_regular_graph(n, z))
  npartitions = _npartitions(g, nothing, nvertices_per_partition)
  partitions = [
    [nvertices_per_partition * (i - 1) + j for j in 1:nvertices_per_partition] for
    i in 1:npartitions
  ]
  pg = PartitionedGraph(g, partitions)

  pg_1 = subgraph(pg, partitions[1])
  pg_2 = subgraph(pg, [PartitionVertex(1)])

  @test pg_1 == pg_2
end

@testset "Test NamedGraphs Functions on Partitioned Graph" begin
  functions = [
    is_tree,
    NamedGraphs.default_root_vertex,
    spanning_tree,
    spanning_forest,
    center,
    diameter,
    radius,
  ]
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
