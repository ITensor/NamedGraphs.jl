@eval module $(gensym())
using Graphs:
    AbstractGraph,
    Graphs,
    a_star,
    center,
    connected_components,
    diameter,
    edges,
    has_edge,
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
using NamedGraphs:
    NamedEdge,
    NamedGraph,
    NamedGraphs,
    parent_graph_indices,
    to_graph_index,
    Vertices,
    Edges
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
    AbstractPartitionedGraph,
    PartitionedGraph,
    PartitionedGraphs,
    PartitionedView,
    QuotientEdge,
    QuotientEdgeEdge,
    QuotientEdgeEdges,
    QuotientEdges,
    QuotientEdgesEdges,
    QuotientVertex,
    QuotientVertexVertex,
    QuotientVertexVertices,
    QuotientVertices,
    QuotientVerticesVertices,
    QuotientView,
    boundary_quotientedges,
    departition,
    has_quotientvertex,
    has_quotientedge,
    partitioned_edges,
    partitioned_vertices,
    partitionedgraph,
    quotient_graph,
    to_quotient_index,
    quotientedge,
    quotientedges,
    quotientvertex,
    quotientvertices,
    rem_quotientvertex!,
    unpartition,
    unpartitioned_graph,
    QuotientVertexSlice,
    QuotientEdgeSlice
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
    @test eltype(collect(quotientvertices(pg))) == QuotientVertex{Int64}
    @test eltype(collect(quotientedges(pg))) == QuotientEdge{Int64, NamedEdge{Int64}}
    @test is_tree(QuotientView(pg))
    @test nv(pg) == nx * ny
    @test nv(QuotientView(pg)) == nx
    pg_c = copy(pg)
    @test pg_c == pg

    #PartionsGraphView test
    pgv = QuotientView(pg)
    @test collect(vertices(pgv)) == collect(parent.(quotientvertices(pg)))
    @test edges(pgv) == parent.(quotientedges(pg))
    @test is_tree(pgv) == true
    @test neighbors(pgv, 1) == [2]
    @test issetequal(vertices(subgraph(pgv, [2, 3, 4])), [2, 3, 4])
    @test issetequal(edges(subgraph(pgv, [2, 3, 4])), edgetype(pgv).([2 => 3, 3 => 4]))

    #Same partitioning but with a dictionary constructor
    partition_dict = Dictionary([first(partition) for partition in partitions], partitions)
    pg = PartitionedGraph(g, partition_dict)
    @test vertextype(QuotientView(pg)) == vertextype(g)
    @test vertextype(unpartitioned_graph(pg)) == vertextype(g)
    @test eltype(collect(quotientvertices(pg))) == QuotientVertex{Tuple{Int64, Int64}}
    @test eltype(collect(quotientedges(pg))) == QuotientEdge{Tuple{Int64, Int64}, NamedEdge{Tuple{Int64, Int64}}}
    @test is_tree(QuotientView(pg))
    @test nv(pg) == nx * ny
    @test nv(pg, QuotientVertex((1, 1))) == ny
    @test_throws ArgumentError nv(pg, QuotientVertex((11, 11)))
    @test nv(QuotientView(pg)) == nx
    @test ne(pg) == (nx - 1) * ny + nx * (ny - 1)
    @test ne(pg, QuotientEdge((1, 1) => (2, 1))) == ny
    @test_throws ArgumentError ne(pg, QuotientEdge((1, 1) => (1, 2)))
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
    @test Set(quotientvertices(pg)) == Set(quotientvertices(pg, vertices(g)))
    @test Set(quotientedges(pg)) == Set(quotientedges(pg, edges(g)))
    @test is_self_loop(quotientedge(pg, (1, 1, 1) => (1, 1, 2)))
    @test !is_self_loop(quotientedge(pg, (1, 2, 1) => (1, 1, 1)))
    @test quotientvertex(pg, (1, 1, 1)) == quotientvertex(pg, (1, 1, nz))
    @test quotientvertex(pg, (2, 1, 1)) != quotientvertex(pg, (1, 1, nz))

    @test quotientedge(pg, (1, 1, 1) => (2, 1, 1)) ==
        quotientedge(pg, (1, 1, 2) => (2, 1, 2))
    inter_column_edges = [(1, 1, i) => (2, 1, i) for i in 1:nz]
    @test length(quotientedges(pg, inter_column_edges)) == 1
    @test length(quotientvertices(pg, [(1, 2, i) for i in 1:nz])) == 1
    @test all([length(edges(pg, pe)) == nz for pe in quotientedges(pg)])

    boundary_sizes = [length(boundary_quotientedges(pg, pv)) for pv in quotientvertices(pg)]
    #Partitions into a square grid so each partition should have maximum 4 incoming edges and minimum 2
    @test maximum(boundary_sizes) == 4
    @test minimum(boundary_sizes) == 2
    @test isempty(boundary_quotientedges(pg, quotientvertices(pg)))
end

@testset "Test Partitioned Graph Vertex/Edge Addition and Removal" begin
    nx, ny = 10, 10
    g = named_grid((nx, ny))

    partitions = [[(i, j) for j in 1:ny] for i in 1:nx]
    pg = PartitionedGraph(g, partitions)

    pv = QuotientVertex(5)
    v_set = vertices(pg, pv)
    edges_involving_v_set = boundary_edges(g, v_set)

    #Strip the middle column from pg via the partitioned graph vertex, and make a new pg
    rem_quotientvertex!(pg, pv)
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
    @test has_quotientvertex(pg, pv)
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

    pg_1 = subgraph(pg, QuotientVertex.(subgraph_partitioned_vertices))
    pg_2 = subgraph(pg, subgraph_vertices)
    @test pg_1 == pg_2
    @test nv(pg_1) == length(subgraph_vertices)
    @test nv(QuotientView(pg_1)) == length(subgraph_partitioned_vertices)

    subgraph_partitioned_vertex = 3
    subgraph_vertices = partitions[subgraph_partitioned_vertex]
    g_1 = subgraph(pg, QuotientVertex(subgraph_partitioned_vertex))
    pg_1 = subgraph(pg, subgraph_vertices)
    @test pg_1 == subgraph(g, subgraph_vertices)
    @test g_1 == subgraph(g, subgraph_vertices)

    @test subgraph(pg, QuotientVertex(1)) isa typeof(g)
    @test subgraph(pg, QuotientVertex(1)[2]) isa typeof(g)
    @test nv(subgraph(pg, QuotientVertex(1)[2])) == 1
    @test subgraph(pg, QuotientVertex(1)[Vertices([1, 2])]) isa typeof(g)
    @test nv(subgraph(pg, QuotientVertex(1)[Vertices([1, 2])])) == 2

    @test subgraph(pg, [QuotientVertex(1)]) isa typeof(pg)
    @test subgraph(pg, [QuotientVertex(1), QuotientVertex(2)]) isa typeof(pg)
    @test subgraph(pg, QuotientVertices([1, 2])) isa typeof(pg)
    @test nv(subgraph(pg, QuotientVertices([1, 2]))) == 6
    @test subgraph(pg, QuotientVertices([1, 2, 3, 4])) == pg

    @test subgraph(pg, [QuotientVertex(1)[Vertices([1, 2])]]) isa typeof(pg)
    let pg_subgraph = subgraph(pg, [QuotientVertex(1)[Vertices([1, 2])], QuotientVertex(1)[Vertices([4])]])
        @test nv(pg_subgraph) == 3
        @test nv(QuotientView(pg_subgraph)) == 2
        @test collect(vertices(pg_subgraph, QuotientVertex(1))) == [1, 2]
        @test collect(vertices(pg_subgraph, QuotientVertex(2))) == [4]
    end
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

# Not an AbstractPartitionedGraph
struct MyUnpartitionedGraph{V} <: AbstractGraph{V}
    g::NamedGraph{V}
end

Graphs.edges(mg::MyUnpartitionedGraph) = edges(mg.g)
Graphs.vertices(mg::MyUnpartitionedGraph) = vertices(mg.g)

Graphs.edgetype(mg::MyUnpartitionedGraph) = edgetype(mg.g)
Graphs.has_edge(mg::MyUnpartitionedGraph, e) = has_edge(mg.g, e)

Graphs.is_directed(mg::MyUnpartitionedGraph) = is_directed(mg.g)

struct MyGraph{V, P} <: AbstractGraph{V}
    g::NamedGraph{V}
    partitioned_vertices::P
end


Graphs.edges(mg::MyGraph) = edges(mg.g)
Graphs.vertices(mg::MyGraph) = vertices(mg.g)

Graphs.edgetype(mg::MyGraph) = edgetype(mg.g)
Graphs.has_edge(mg::MyGraph, e) = has_edge(mg.g, e)

Graphs.is_directed(mg::MyGraph) = is_directed(mg.g)
NamedGraphs.position_graph(mg::MyGraph) = NamedGraphs.position_graph(mg.g)

PartitionedGraphs.partitioned_vertices(mg::MyGraph) = mg.partitioned_vertices
PartitionedGraphs.quotient_graph_type(::Type{<:MyGraph}) = NamedGraph{Int}

struct MyFastGraph{V, PV, QG, PE} <: AbstractGraph{V}
    g::NamedGraph{V}
    partitioned_vertices::PV
    quotient_graph::QG
    partitioned_edges::PE
end

PartitionedGraphs.partitioned_vertices(mg::MyFastGraph) = mg.partitioned_vertices
PartitionedGraphs.quotient_graph(mg::MyFastGraph) = mg.quotient_graph
PartitionedGraphs.partitioned_edges(mg::MyFastGraph) = mg.partitioned_edges

struct WrapperGraph{V, G <: AbstractGraph{V}} <: AbstractGraph{V}
    g::G
end

Graphs.edges(wg::WrapperGraph) = edges(wg.g)
Graphs.vertices(wg::WrapperGraph) = vertices(wg.g)

Graphs.is_directed(wg::WrapperGraph) = is_directed(wg.g)
NamedGraphs.position_graph(wg::WrapperGraph) = NamedGraphs.position_graph(wg.g)

PartitionedGraphs.partitioned_vertices(wg::WrapperGraph) = partitioned_vertices(wg.g)

@testset "Partitioning of non-partitioned graphs" begin
    nx, ny = 4, 4

    g = named_grid((nx, ny))

    partitions = [[(i, j) for j in 1:ny] for i in 1:nx]

    @test nv(QuotientView(g)) == 1
    @test ne(QuotientView(g)) == 0

    @test nv(QuotientView(MyUnpartitionedGraph(g))) == 1
    @test ne(QuotientView(MyUnpartitionedGraph(g))) == 0

    @test nv(quotient_graph(MyUnpartitionedGraph(g))) == 1
    @test ne(quotient_graph(MyUnpartitionedGraph(g))) == 0

    @test nv(PartitionedView(g, partitions)) == nx * ny
    @test ne(PartitionedView(g, partitions)) == (nx - 1) * ny + nx * (ny - 1)

    @test nv(QuotientView(PartitionedView(g, partitions))) == nx
    @test ne(QuotientView(PartitionedView(g, partitions))) == ny - 1

    qg = quotient_graph(PartitionedView(g, partitions))
    pes = partitioned_edges(PartitionedView(g, partitions))

    mg = MyGraph(g, partitions)
    @test nv(QuotientView(mg)) == nx
    @test ne(QuotientView(mg)) == ny - 1

    @test quotient_graph(mg) == qg
    @test partitioned_edges(mg) == pes

    mfg = MyFastGraph(g, partitions, qg, pes)

    # Test overloads are working correctly.
    @test partitioned_vertices(mfg) === partitions
    @test quotient_graph(mfg) === qg
    @test partitioned_edges(mfg) === pes
end

@testset "Nesting partitions" begin
    nx, ny, nz = 3, 4, 5
    g = named_grid((nx, ny, nz))

    # First partition: columns along z-axis
    p1 = Dict((i, j) => [(i, j, k) for k in 1:nz] for i in 1:nx for j in 1:ny)
    # Second partition: columns along y-axis
    p2 = [[(i, j, k) for j in 1:ny] for i in 1:nx for k in 1:nz]

    wg = WrapperGraph(g)
    pwg1 = partitionedgraph(wg, p1)
    @test nv(QuotientView(pwg1)) == nx * ny
    pwg2 = partitionedgraph(wg, p2)
    @test nv(QuotientView(pwg2)) == nx * nz

    pwg1_2 = partitionedgraph(pwg2, p1)
    @test nv(QuotientView(pwg1)) == nx * ny
    pwg2_1 = partitionedgraph(pwg1, p2)
    @test nv(QuotientView(pwg2)) == nx * nz

    @test departition(pwg1_2) == pwg2
    @test departition(pwg2_1) == pwg1
    @test unpartition(pwg1_2) == wg

    p1q = [[(i, j) for j in 1:ny] for i in 1:nx]
    partitionedgraph(QuotientView(pwg1), p1q)
end

@testset "Index transformations" begin
    nx, ny = 3, 3
    g = named_grid((nx, ny))
    partitions = [[(i, j) for j in 1:ny] for i in 1:nx]

    g = PartitionedGraph(g, partitions)

    @testset "Vertices" begin

        # runic: off
        V       = vertextype(g)
        VS      = Vertices
        QVV     = QuotientVertexVertex{V}
        QVVS    = QuotientVertexVertices
        QV      = QuotientVertex
        QVS     = QuotientVertices
        QVSVS   = QuotientVerticesVertices

        VSlice{GI, V}   = QuotientVertexSlice{V, GI}

        # runic: on

        @testset "`to_graph_index`" begin
            to_graph_index_type = (G, I) -> Base.promote_op(NamedGraphs.to_graph_index, G, I)
            # runic: off
            @test Union{} != to_graph_index_type(AbstractGraph, V)            <: V
            @test Union{} != to_graph_index_type(AbstractGraph, QVV)          <: V
            @test Union{} != to_graph_index_type(AbstractGraph, QV)           <: QVVS

            @test Union{} != to_graph_index_type(AbstractGraph, VS)           <: VS
            @test Union{} != to_graph_index_type(AbstractGraph, Vector{V})    <: Vector{V}
            @test Union{} != to_graph_index_type(AbstractGraph, Vector{QVV})  <: VS
            @test Union{} != to_graph_index_type(AbstractGraph, QVVS)         <: QVVS

            @test Union{} != to_graph_index_type(AbstractGraph, Vector{QVVS}) <: QVSVS
            @test Union{} != to_graph_index_type(AbstractGraph, Vector{QV})   <: QVS
            @test Union{} != to_graph_index_type(AbstractGraph, QVSVS)        <: QVSVS
            @test Union{} != to_graph_index_type(AbstractGraph, QVS)          <: QVS
            # runic: on
        end

        @testset "`to_vertices`" begin
            to_vertices_type = (G, I) -> Base.promote_op(NamedGraphs.to_vertices, G, I)
            # runic: off
            @test Union{} != to_vertices_type(AbstractGraph, V)               <: V
            @test Union{} != to_vertices_type(AbstractGraph, QVV)             <: VSlice{<:QVVS}
            @test Union{} != to_vertices_type(AbstractGraph, QV)              <: VSlice{<:QVVS}

            @test Union{} != to_vertices_type(AbstractGraph, VS)              <: VS
            @test Union{} != to_vertices_type(AbstractGraph, Vector{V})       <: VS
            @test Union{} != to_vertices_type(AbstractGraph, Vector{QVV})     <: VS
            @test Union{} != to_vertices_type(AbstractGraph, QVVS)            <: VSlice{<:QVVS}

            @test Union{} != to_vertices_type(NamedGraph, Vector{QVVS})       <: VSlice{<:QVSVS}
            @test Union{} != to_vertices_type(NamedGraph, Vector{QV})         <: VSlice{<:QVSVS}
            @test Union{} != to_vertices_type(NamedGraph, QVSVS)              <: VSlice{<:QVSVS}
            @test Union{} != to_vertices_type(NamedGraph, QVS)                <: VSlice{<:QVSVS}

            @test Union{} != to_vertices_type(PartitionedGraph, Vector{QVVS}) <: QVSVS
            @test Union{} != to_vertices_type(PartitionedGraph, Vector{QV})   <: QVSVS
            @test Union{} != to_vertices_type(PartitionedGraph, QVSVS)        <: QVSVS
            @test Union{} != to_vertices_type(PartitionedGraph, QVS)          <: QVSVS
            # runic: on
        end

    end

    @testset "Edges" begin
        # runic: off
        P       = Pair
        E       = edgetype(g)
        V       = vertextype(E)
        ES      = Edges
        QEE     = QuotientEdgeEdge{V, E}
        QEES    = QuotientEdgeEdges
        QE      = QuotientEdge
        QES     = QuotientEdges
        QESES   = QuotientEdgesEdges
        # runic: on

        ESlice{GI, V, E} = QuotientEdgeSlice{V, E, GI}

        @testset "`to_graph_index`" begin
            to_graph_index_type = (G, I) -> Base.promote_op(NamedGraphs.to_graph_index, G, I)
            # runic: off
            @test Union{} != to_graph_index_type(typeof(g), P)            <: E
            @test Union{} != to_graph_index_type(typeof(g), E)            <: E
            @test Union{} != to_graph_index_type(typeof(g), QEE)          <: E
            @test Union{} != to_graph_index_type(typeof(g), QE)           <: QEES

            @test Union{} != to_graph_index_type(typeof(g), ES)           <: ES
            @test Union{} != to_graph_index_type(typeof(g), Vector{P})    <: ES
            @test Union{} != to_graph_index_type(typeof(g), Vector{E})    <: ES
            @test Union{} != to_graph_index_type(typeof(g), Vector{QEE})  <: ES
            @test Union{} != to_graph_index_type(typeof(g), QEES)         <: QEES

            @test Union{} != to_graph_index_type(typeof(g), Vector{QEES}) <: QESES
            @test Union{} != to_graph_index_type(typeof(g), Vector{QE})   <: QES
            @test Union{} != to_graph_index_type(typeof(g), QESES)        <: QESES
            @test Union{} != to_graph_index_type(typeof(g), QES)          <: QES
            # runic: on
        end
        @testset "`to_edges`" begin
            to_edges_type = (G, I) -> Base.promote_op(NamedGraphs.to_edges, G, I)
            # runic: off
            @test Union{} != to_edges_type(typeof(g), P)                  <: ES
            @test Union{} != to_edges_type(typeof(g), E)                  <: ES
            @test Union{} != to_edges_type(typeof(g), QEE)                <: ESlice{<:QEES}
            @test Union{} != to_edges_type(typeof(g), QE)                 <: ESlice{<:QEES}

            @test Union{} != to_edges_type(typeof(g), ES)                 <: ES
            @test Union{} != to_edges_type(typeof(g), Vector{P})          <: ES
            @test Union{} != to_edges_type(typeof(g), Vector{E})          <: ES
            @test Union{} != to_edges_type(typeof(g), Vector{QEE})        <: ES
            @test Union{} != to_edges_type(typeof(g), QEES)               <: ESlice{<:QEES}

            @test Union{} != to_edges_type(typeof(g), Vector{QEES})       <: ESlice{<:QESES}
            @test Union{} != to_edges_type(typeof(g), Vector{QE})         <: ESlice{<:QESES}
            @test Union{} != to_edges_type(typeof(g), QESES)              <: ESlice{<:QESES}
            @test Union{} != to_edges_type(typeof(g), QES)                <: ESlice{<:QESES}
            # runic: on
        end
    end
end

@testset  "Subgraphs" begin
    nx, ny = 3, 3
    g = named_grid((nx, ny))
    partitions = [[(i, j) for j in 1:ny] for i in 1:nx]

    g = PartitionedGraph(g, partitions)

    # runic: off
    V       = vertextype(g)
    VS      = Vertices
    QVV     = QuotientVertexVertex{V}
    QVVS    = QuotientVertexVertices
    QV      = QuotientVertex
    QVS     = QuotientVertices
    QVSVS   = QuotientVerticesVertices

    PG      = typeof(g)
    UG      = typeof(unpartitioned_graph(g))
    # runic: on

    @testset "Basic" begin

        @test subgraph(g, QuotientVertex(1)) == subgraph(g, vertices(g, QuotientVertex(1)))
        @test subgraph(g, QuotientVertex(1)) == subgraph(g, [(1, 1), (1, 2), (1, 3)])

        @test subgraph(g, QuotientVertices([1])) isa PG

        @test has_quotientvertex(subgraph(g, QuotientVertices([1, 2])), QuotientVertex(1))
        @test has_quotientvertex(subgraph(g, QuotientVertices([1, 2])), QuotientVertex(2))
        @test !has_quotientvertex(subgraph(g, QuotientVertices([1, 2])), QuotientVertex(3))

        @test has_quotientedge(subgraph(g, QuotientVertices([1, 2])), QuotientEdge(1 => 2))
        @test !has_quotientedge(subgraph(g, QuotientVertices([1, 2])), QuotientEdge(2 => 3))

        @test subgraph(QuotientView(g), [1, 2]) isa QuotientView
        @test parent(subgraph(QuotientView(g), [1, 2])) == subgraph(g, QuotientVertices([1, 2]))

        @test subgraph(g, [QuotientVertex(1)[(1, 1)], QuotientVertex(2)[(2, 1)]]) isa UG

        sg = subgraph(g, [QuotientVertex(1)[Vertices([(1, 1), (1, 2)])], QuotientVertex(2)[Vertices([(2, 1)])]])
        @test sg isa PG
        @test has_quotientvertex(sg, QuotientVertex(1))
        @test has_quotientvertex(sg, QuotientVertex(2))
        @test !has_quotientvertex(sg, QuotientVertex(3))
        @test has_vertex(sg, (1, 1))
        @test has_vertex(sg, (1, 2))
        @test !has_vertex(sg, (1, 3))
        @test has_vertex(sg, (2, 1))

    end

    @testset "`getindex`" begin

        @test_throws MethodError g[(1, 1)]
        @test_throws MethodError g[QuotientVertex(1)[(1, 1)]]

        getindex_type = (G, I) -> Base.promote_op(Base.getindex, G, I)
        # runic: off
        @test Union{} != getindex_type(PG, VS)                  <: NamedGraph
        @test Union{} != getindex_type(PG, Vector{QVV})         <: NamedGraph
        @test Union{} != getindex_type(PG, QV)                  <: NamedGraph
        @test Union{} != getindex_type(PG, QVVS)                <: NamedGraph

        @test Union{} != getindex_type(PG, Vector{QVVS})        <: PartitionedGraph
        @test Union{} != getindex_type(PG, Vector{QV})          <: PartitionedGraph
        @test Union{} != getindex_type(PG, QVSVS)               <: PartitionedGraph
        @test Union{} != getindex_type(PG, QVS)                 <: PartitionedGraph
        # runic: on
    end
end
end
