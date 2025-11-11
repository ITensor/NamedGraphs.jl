@eval module $(gensym())
using Graphs:
    a_star,
    center,
    connected_components,
    diameter,
    edges,
    has_vertex,
    is_connected,
    is_directed,
    is_tree,
    ne,
    neighbors,
    nv,
    radius,
    random_regular_graph,
    rem_vertex!,
    vertices
using Metis: Metis
using NamedGraphs: NamedEdge, NamedGraph, NamedGraphs
using NamedGraphs.GraphsExtensions:
    add_edges!,
    add_vertices!,
    boundary_edges,
    default_root_vertex,
    edgetype,
    forest_cover,
    is_path_graph,
    is_self_loop,
    spanning_forest,
    spanning_tree,
    subgraph,
    vertextype
using NamedGraphs.NamedGraphGenerators:
    named_comb_tree, named_grid, named_triangular_lattice_graph
using NamedGraphs.OrderedDictionaries: OrderedDictionary
using NamedGraphs.PartitionedGraphs:
    PartitionedGraph,
    QuotientView,
    SuperEdge,
    SuperVertex,
    boundary_superedges,
    superedge,
    superedges,
    supervertex,
    supervertices,
    unpartitioned_graph,
    rem_supervertex!,
    has_supervertex
using Dictionaries: Dictionary, dictionary
using Pkg: Pkg
using Test: @test, @testset, @test_throws

@testset "Test Partitioned Graph Constructors" begin
    nx, ny = 10, 10
    g = named_grid((nx, ny))

    #Partition it column-wise (into a 1D chain)
    partitions = [[(i, j) for j in 1:ny] for i in 1:nx]
    pg = PartitionedGraph(g, partitions)
    @test vertextype(QuotientView(pg)) == Int64
    @test vertextype(unpartitioned_graph(pg)) == vertextype(g)
    @test isa(supervertices(pg), OrderedDictionary{Int64, SuperVertex{Int64}})
    @test isa(superedges(pg), Vector{SuperEdge{Int64, NamedEdge{Int64}}})
    @test is_tree(QuotientView(pg))
    @test nv(pg) == nx * ny
    @test nv(QuotientView(pg)) == nx
    pg_c = copy(pg)
    @test pg_c == pg

    #PartionsGraphView test
    pgv = QuotientView(pg)
    @test vertices(pgv) == parent.(supervertices(pg))
    @test edges(pgv) == parent.(superedges(pg))
    @test is_tree(pgv) == true
    @test neighbors(pgv, 1) == [2]
    @test issetequal(vertices(subgraph(pgv, [2, 3, 4])), [2, 3, 4])
    @test issetequal(edges(subgraph(pgv, [2, 3, 4])), edgetype(pgv).([2 => 3, 3 => 4]))

    #Same partitioning but with a dictionary constructor
    partition_dict = Dictionary([first(partition) for partition in partitions], partitions)
    pg = PartitionedGraph(g, partition_dict)
    @test vertextype(QuotientView(pg)) == vertextype(g)
    @test vertextype(unpartitioned_graph(pg)) == vertextype(g)
    @test isa(
        supervertices(pg),
        OrderedDictionary{Tuple{Int64, Int64}, SuperVertex{Tuple{Int64, Int64}}},
    )
    @test isa(
        superedges(pg),
        Vector{SuperEdge{Tuple{Int64, Int64}, NamedEdge{Tuple{Int64, Int64}}}},
    )
    @test is_tree(QuotientView(pg))
    @test nv(pg) == nx * ny
    @test nv(pg, SuperVertex((1, 1))) == ny
    @test_throws ArgumentError nv(pg, SuperVertex((11,11)))
    @test nv(QuotientView(pg)) == nx
    @test ne(pg) == (nx - 1) * ny + nx * (ny - 1)
    @test ne(pg, SuperEdge((1, 1) => (2, 1))) == ny
    @test_throws ArgumentError ne(pg, SuperEdge((1, 1) => (1, 2)))
    @test ne(QuotientView(pg)) == 9
    pg_c = copy(pg)
    @test pg_c == pg

    #Partition the whole thing into just 1 vertex
    pg = PartitionedGraph([i for i in 1:nx])
    @test unpartitioned_graph(pg) == QuotientView(pg)
    @test nv(pg) == nx
    @test nv(QuotientView(pg)) == nx
    @test ne(pg) == 0
    @test ne(QuotientView(pg)) == 0
    pg_c = copy(pg)
    @test pg_c == pg
end

@testset "Test Partitioned Graph Partition Edge and Vertex Finding" begin
    nx, ny, nz = 4, 4, 4
    g = named_grid((nx, ny, nz))

    #Partition it column-wise (into a square grid)
    partitions = [[(i, j, k) for k in 1:nz] for i in 1:nx for j in 1:ny]
    pg = PartitionedGraph(g, partitions)
    @test Set(supervertices(pg)) == Set(supervertices(pg, vertices(g)))
    @test Set(superedges(pg)) == Set(superedges(pg, edges(g)))
    @test is_self_loop(superedge(pg, (1, 1, 1) => (1, 1, 2)))
    @test !is_self_loop(superedge(pg, (1, 2, 1) => (1, 1, 1)))
    @test supervertex(pg, (1, 1, 1)) == supervertex(pg, (1, 1, nz))
    @test supervertex(pg, (2, 1, 1)) != supervertex(pg, (1, 1, nz))

    @test superedge(pg, (1, 1, 1) => (2, 1, 1)) ==
        superedge(pg, (1, 1, 2) => (2, 1, 2))
    inter_column_edges = [(1, 1, i) => (2, 1, i) for i in 1:nz]
    @test length(superedges(pg, inter_column_edges)) == 1
    @test length(supervertices(pg, [(1, 2, i) for i in 1:nz])) == 1
    @test all([length(edges(pg, pe)) == nz for pe in superedges(pg)])

    boundary_sizes = [length(boundary_superedges(pg, pv)) for pv in supervertices(pg)]
    #Partitions into a square grid so each partition should have maximum 4 incoming edges and minimum 2
    @test maximum(boundary_sizes) == 4
    @test minimum(boundary_sizes) == 2
    @test isempty(boundary_superedges(pg, supervertices(pg)))
end

@testset "Test Partitioned Graph Vertex/Edge Addition and Removal" begin
    nx, ny = 10, 10
    g = named_grid((nx, ny))

    partitions = [[(i, j) for j in 1:ny] for i in 1:nx]
    pg = PartitionedGraph(g, partitions)

    pv = SuperVertex(5)
    v_set = vertices(pg, pv)
    edges_involving_v_set = boundary_edges(g, v_set)

    #Strip the middle column from pg via the partitioned graph vertex, and make a new pg
    rem_supervertex!(pg, pv)
    @test !is_connected(unpartitioned_graph(pg)) && !is_connected(QuotientView(pg))
    @test parent(pv) ∉ vertices(QuotientView(pg))
    @test !has_vertex(pg, pv)
    @test nv(pg) == (nx - 1) * ny
    @test nv(QuotientView(pg)) == nx - 1
    @test !is_tree(QuotientView(pg))

    #Add the column back to the in place graph
    add_vertices!(pg, map(v -> pv[v], v_set))
    add_edges!(pg, edges_involving_v_set)
    @test is_connected(pg.graph) 
    @test is_path_graph(QuotientView(pg))
    @test parent(pv) ∈ vertices(QuotientView(pg))
    @test has_supervertex(pg, pv)
    @test is_tree(QuotientView(pg))
    @test nv(pg) == nx * ny
    @test nv(QuotientView(pg)) == nx
end

@testset "Test Partitioned Graph Subgraph Functionality" begin
    n, z = 12, 4
    g = NamedGraph(random_regular_graph(n, z))
    partitions = dictionary(
        [
            1 => [1, 2, 3], 2 => [4, 5, 6], 3 => [7, 8, 9], 4 => [10, 11, 12],
        ]
    )
    pg = PartitionedGraph(g, partitions)

    subgraph_partitioned_vertices = [1, 2]
    subgraph_vertices = reduce(
        vcat, [partitions[spv] for spv in subgraph_partitioned_vertices]
    )

    pg_1 = subgraph(pg, SuperVertex.(subgraph_partitioned_vertices))
    pg_2 = subgraph(pg, subgraph_vertices)
    @test pg_1 == pg_2
    @test nv(pg_1) == length(subgraph_vertices)
    @test nv(QuotientView(pg_1)) == length(subgraph_partitioned_vertices)

    subgraph_partitioned_vertex = 3
    subgraph_vertices = partitions[subgraph_partitioned_vertex]
    g_1 = subgraph(pg, SuperVertex(subgraph_partitioned_vertex))
    pg_1 = subgraph(pg, subgraph_vertices)
    @test unpartitioned_graph(pg_1) == subgraph(g, subgraph_vertices)
    @test g_1 == subgraph(g, subgraph_vertices)
end

@testset "Test NamedGraphs Functions on Partitioned Graph" begin
    functions = (is_tree, default_root_vertex, center, diameter, radius)
    gs = (
        named_comb_tree((4, 4)),
        named_grid((2, 2, 2)),
        NamedGraph(random_regular_graph(12, 3)),
        named_triangular_lattice_graph(7, 7),
    )
    for f in functions
        for g in gs
            pg = PartitionedGraph(g, [vertices(g)])
            @test f(pg) == f(unpartitioned_graph(pg))
            @test nv(pg) == nv(g)
            @test nv(QuotientView(pg)) == 1
            @test ne(pg) == ne(g)
            @test ne(QuotientView(pg)) == 0
        end
    end
end

@testset "Graph partitioning" begin
    g = named_grid((4, 4))
    npartitions = 4
    backends = ["metis"]
    if !Sys.iswindows()
        # `KaHyPar` doesn't work on Windows.
        Pkg.add("KaHyPar"; io = devnull)
        push!(backends, "kahypar")
    end
    for backend in backends
        pg = PartitionedGraph(g; npartitions, backend = "metis")
        @test pg isa PartitionedGraph
        @test nv(QuotientView(pg)) == npartitions
    end
end
end
