using .GraphsExtensions: GraphsExtensions, all_edges, directed_graph, empty_graph,
    incident_edges, partition_vertices, rem_edges, rem_edges!, rem_vertices,
    rename_vertices, similar_graph, subgraph
using Dictionaries: dictionary, set!
using Graphs: Graphs, AbstractGraph, AbstractSimpleGraph, IsDirected, SimpleDiGraph,
    SimpleEdge, SimpleGraph, a_star, add_edge!, adjacency_matrix, bfs_parents, boruvka_mst,
    connected_components, degree, edges, has_path, indegree, induced_subgraph, inneighbors,
    is_connected, is_cyclic, kruskal_mst, ne, neighborhood, neighborhood_dists, nv,
    outdegree, prim_mst, rem_edge!, spfa_shortest_paths, vertices, weights
using SimpleTraits: SimpleTraits, @traitfn, Not

abstract type AbstractNamedGraph{V} <: AbstractGraph{V} end

#
# Required for interface
#

"""
    coded_vertex(graph::AbstractNamedGraph, vertex) -> Int

The code of `vertex` in `graph`, i.e. the corresponding vertex of
[`coded_graph(graph)`](@ref coded_graph). `coded_vertex(graph, ·)` and
[`decoded_vertex(graph, ·)`](@ref decoded_vertex) are inverse bijections between
`vertices(graph)` and `Base.OneTo(nv(graph))`.

Codes are not stable across mutation: adding or removing vertices may reassign
the codes of other vertices.

The curried form `coded_vertex(graph)` returns the function `v -> coded_vertex(graph, v)`.
"""
coded_vertex(graph::AbstractNamedGraph, vertex) = not_implemented()
coded_vertex(graph::AbstractSimpleGraph, vertex) = vertex

"""
    decoded_vertex(graph::AbstractNamedGraph, code::Integer)

The vertex of `graph` whose code is `code`, i.e. the vertex corresponding to the
vertex `code` of [`coded_graph(graph)`](@ref coded_graph). Inverse of
[`coded_vertex`](@ref).

The curried form `decoded_vertex(graph)` returns the function `c -> decoded_vertex(graph, c)`.
"""
decoded_vertex(graph::AbstractNamedGraph, code::Integer) = not_implemented()
decoded_vertex(graph::AbstractSimpleGraph, code::Integer) = code

Graphs.rem_vertex!(graph::AbstractNamedGraph, vertex) = not_implemented()
Graphs.add_vertex!(graph::AbstractNamedGraph, vertex) = not_implemented()

GraphsExtensions.rename_vertices(f::Function, g::AbstractNamedGraph) = not_implemented()

#
# Derived interface (overload for performance)
#

"""
    coded_graph(graph::AbstractNamedGraph) -> AbstractGraph{Int}

The graph in coded form: a graph with the same topology as `graph` whose
vertices are the codes `1:nv(graph)` of the vertices of `graph`, i.e. it has
the edge `coded_vertex(graph, u) => coded_vertex(graph, v)` if and only if
`graph` has the edge `u => v`.

May be a stored field or a view of `graph`; mutate the graph only through
`graph`.
"""
coded_graph(graph::AbstractNamedGraph) = CodedGraphView(graph)
coded_graph(graph::AbstractSimpleGraph) = graph

"""
    vertices(graph::AbstractNamedGraph) -> AbstractIndices

The set of vertices of `graph`: an `AbstractIndices` containing each vertex
exactly once, with fast membership testing. The iteration order is
unspecified; code that needs the vertices in code order should say so
explicitly, for example `map(decoded_vertex(graph), 1:nv(graph))`.

The output is a live read-only view of the graph: do not mutate it directly,
and do not rely on it (or containers sharing its state) across mutations of
the graph.
"""
Graphs.vertices(graph::AbstractNamedGraph) = VerticesView(graph)

# Curried forms, following `Base.Fix1` conventions like `isequal(x)`.
coded_vertex(graph::AbstractNamedGraph) = Base.Fix1(coded_vertex, graph)
decoded_vertex(graph::AbstractNamedGraph) = Base.Fix1(decoded_vertex, graph)

"""
    decoded_vertices(graph::AbstractNamedGraph) -> AbstractVector

The vertices of `graph` in code order, i.e.
`decoded_vertices(graph)[c] == decoded_vertex(graph, c)`.

The output is a live read-only view of the graph (possibly internal graph
state): do not mutate it directly, and do not rely on it across mutations of
the graph — make a copy (for example with `copy` or `collect`) for a snapshot
that stays valid.
"""
decoded_vertices(graph) = DecodedVerticesView(graph)

"""
    coded_vertices(graph::AbstractNamedGraph) -> AbstractDictionary{_, Int}

The code of each vertex of `graph` as a dictionary, i.e.
`coded_vertices(graph)[v] == coded_vertex(graph, v)`, keyed by
`vertices(graph)`.

The output is a live read-only view of the graph (possibly internal graph
state): do not mutate it directly, and do not rely on it across mutations of
the graph — make a copy for a snapshot that stays valid.
"""
coded_vertices(graph) = CodedVerticesView(graph)

# TODO: Is this a good definition? Maybe make it generic to any graph?
function GraphsExtensions.permute_vertices(graph::AbstractNamedGraph, permutation)
    return subgraph(graph, map(decoded_vertex(graph), permutation))
end

Graphs.edgetype(graph::AbstractNamedGraph) = edgetype(typeof(graph))
Graphs.edgetype(::Type{<:AbstractNamedGraph}) = not_implemented()

# In terms of `coded_graph_type`
# is_directed(::Type{<:AbstractNamedGraph}) = not_implemented()

GraphsExtensions.convert_vertextype(::Type{V}, g::AbstractNamedGraph{V}) where {V} = g
GraphsExtensions.convert_vertextype(::Type, g::AbstractNamedGraph) = not_implemented()

Base.copy(graph::AbstractNamedGraph) = copyto!(similar_graph(graph), graph)

function Graphs.merge_vertices!(
        graph::AbstractNamedGraph, merge_vertices; merged_vertex = first(merge_vertices)
    )
    return not_implemented()
end

#
# Derived interface
#

coded_graph_type(graph::AbstractNamedGraph) = typeof(coded_graph(graph))
coded_graph_type(T::Type{<:AbstractNamedGraph}) = Base.promote_op(coded_graph, T)

function Graphs.has_vertex(graph::AbstractNamedGraph, vertex)
    return vertex ∈ vertices(graph)
end

Graphs.SimpleDiGraph(graph::AbstractNamedGraph) = SimpleDiGraph(coded_graph(graph))

Base.zero(G::Type{<:AbstractNamedGraph}) = G()

# Default, can overload
Base.eltype(graph::AbstractNamedGraph) = eltype(vertices(graph))

"""
    coded_edge(graph::AbstractNamedGraph, edge) -> AbstractEdge{Int}

The edge of [`coded_graph(graph)`](@ref coded_graph) corresponding to `edge`,
i.e. the edge between the codes of the vertices of `edge`.
Inverse of [`decoded_edge`](@ref).
"""
function coded_edge(graph::AbstractNamedGraph, edge::AbstractEdge)
    return edgetype(coded_graph(graph))(
        coded_vertex(graph, src(edge)), coded_vertex(graph, dst(edge))
    )
end

"""
    decoded_edge(graph::AbstractNamedGraph, coded_edge)

The edge of `graph` corresponding to the edge `coded_edge` of
[`coded_graph(graph)`](@ref coded_graph). Inverse of [`coded_edge`](@ref).
"""
function decoded_edge(graph::AbstractNamedGraph, coded_edge::AbstractEdge)
    return edgetype(graph)(
        decoded_vertex(graph, src(coded_edge)),
        decoded_vertex(graph, dst(coded_edge))
    )
end

"""
    edges(graph::AbstractNamedGraph) -> AbstractIndices

The set of edges of `graph`: an `AbstractIndices` containing each edge exactly
once, with membership testing matching `has_edge` (in particular, on
undirected graphs an edge and its reverse are both members while iteration
yields each edge once). The iteration order is unspecified.

The output is a live read-only view of the graph: do not mutate it directly,
and do not rely on it across mutations of the graph.
"""
Graphs.edges(graph::AbstractNamedGraph) = EdgesView(graph)

# TODO: write in terms of a generic function.
for f in [
        :(Graphs.outneighbors),
        :(Graphs.inneighbors),
        :(Graphs.all_neighbors),
        :(Graphs.neighbors),
    ]
    @eval begin
        function $f(graph::AbstractNamedGraph, vertex)
            coded_vertices = $f(coded_graph(graph), coded_vertex(graph, vertex))
            return map(decoded_vertex(graph), coded_vertices)
        end

        # Ambiguity errors with Graphs.jl
        function $f(graph::AbstractNamedGraph, vertex::Integer)
            coded_vertices = $f(coded_graph(graph), coded_vertex(graph, vertex))
            return map(decoded_vertex(graph), coded_vertices)
        end
    end
end

function Graphs.common_neighbors(g::AbstractNamedGraph, u, v)
    return intersect(neighbors(g, u), neighbors(g, v))
end

namedgraph_indegree(graph::AbstractNamedGraph, vertex) = length(inneighbors(graph, vertex))
function namedgraph_outdegree(graph::AbstractNamedGraph, vertex)
    return length(outneighbors(graph, vertex))
end

Graphs.indegree(graph::AbstractNamedGraph, vertex) = namedgraph_indegree(graph, vertex)
Graphs.outdegree(graph::AbstractNamedGraph, vertex) = namedgraph_outdegree(graph, vertex)

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.indegree(graph::AbstractNamedGraph, vertex::Integer)
    return namedgraph_indegree(graph, vertex)
end
function Graphs.outdegree(graph::AbstractNamedGraph, vertex::Integer)
    return namedgraph_outdegree(graph, vertex)
end

@traitfn function namedgraph_degree(graph::AbstractNamedGraph::IsDirected, vertex)
    return indegree(graph, vertex) + outdegree(graph, vertex)
end
@traitfn namedgraph_degree(graph::AbstractNamedGraph::(!IsDirected), vertex) = indegree(
    graph, vertex
)

function Graphs.degree(graph::AbstractNamedGraph, vertex)
    return namedgraph_degree(graph::AbstractNamedGraph, vertex)
end

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.degree(graph::AbstractNamedGraph, vertex::Integer)
    return namedgraph_degree(graph::AbstractNamedGraph, vertex)
end

function Graphs.degree_histogram(g::AbstractNamedGraph, degfn = degree)
    hist = Dictionary{Int, Int}()
    for v in vertices(g)        # minimize allocations by
        for d in degfn(g, v)    # iterating over vertices
            set!(hist, d, get(hist, d, 0) + 1)
        end
    end
    return hist
end

function namedgraph_neighborhood(
        graph::AbstractNamedGraph, vertex, d, distmx = weights(graph); dir = :out
    )
    coded_distmx = dist_matrix_to_coded_dist_matrix(graph, distmx)
    coded_vertices = neighborhood(
        coded_graph(graph), coded_vertex(graph, vertex), d, coded_distmx; dir
    )
    return [
        decoded_vertex(graph, coded_vertex) for coded_vertex in coded_vertices
    ]
end

function Graphs.neighborhood(
        graph::AbstractNamedGraph, vertex, d, distmx = weights(graph); dir = :out
    )
    return namedgraph_neighborhood(graph, vertex, d, distmx; dir)
end

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.neighborhood(
        graph::AbstractNamedGraph, vertex::Integer, d, distmx = weights(graph); dir = :out
    )
    return namedgraph_neighborhood(graph, vertex, d, distmx; dir)
end

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.neighborhood(
        graph::AbstractNamedGraph, vertex::Integer, d, distmx::AbstractMatrix{<:Real};
        dir = :out
    )
    return namedgraph_neighborhood(graph, vertex, d, distmx; dir)
end

function namedgraph_neighborhood_dists(graph::AbstractNamedGraph, vertex, d, distmx; dir)
    coded_distmx = dist_matrix_to_coded_dist_matrix(graph, distmx)
    coded_vertices_and_dists = neighborhood_dists(
        coded_graph(graph), coded_vertex(graph, vertex), d, coded_distmx; dir
    )
    return [
        (decoded_vertex(graph, coded_vertex), dist) for
            (coded_vertex, dist) in coded_vertices_and_dists
    ]
end

function Graphs.neighborhood_dists(
        graph::AbstractNamedGraph, vertex, d, distmx = weights(graph); dir = :out
    )
    return namedgraph_neighborhood_dists(graph, vertex, d, distmx; dir)
end

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.neighborhood_dists(
        graph::AbstractNamedGraph, vertex::Integer, d, distmx = weights(graph); dir = :out
    )
    return namedgraph_neighborhood_dists(graph, vertex, d, distmx; dir)
end

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.neighborhood_dists(
        graph::AbstractNamedGraph, vertex::Integer, d, distmx::AbstractMatrix{<:Real};
        dir = :out
    )
    return namedgraph_neighborhood_dists(graph, vertex, d, distmx; dir)
end

function namedgraph_mincut(graph::AbstractNamedGraph, distmx)
    coded_distmx = dist_matrix_to_coded_dist_matrix(graph, distmx)
    coded_parity, bestcut = Graphs.mincut(coded_graph(graph), coded_distmx)
    parity = dictionary(
        decoded_vertex(graph, c) => p for (c, p) in pairs(coded_parity)
    )
    return parity, bestcut
end

function Graphs.mincut(graph::AbstractNamedGraph, distmx = weights(graph))
    return namedgraph_mincut(graph, distmx)
end

function Graphs.mincut(graph::AbstractNamedGraph, distmx::AbstractMatrix{<:Real})
    return namedgraph_mincut(graph, distmx)
end

# TODO: Make this more generic?
function GraphsExtensions.partition_vertices(
        graph::AbstractNamedGraph; npartitions = nothing, nvertices_per_partition = nothing,
        kwargs...
    )
    vertex_partitions = partition_vertices(
        coded_graph(graph); npartitions, nvertices_per_partition, kwargs...
    )
    # TODO: output the reverse of this dictionary (a Vector of Vector
    # of the vertices in each partition).
    # return Dictionary(vertices(g), partitions)
    return map(vertex_partitions) do vertex_partition
        return map(decoded_vertex(graph), vertex_partition)
    end
end

function namedgraph_a_star(
        graph::AbstractNamedGraph,
        source,
        destination,
        distmx = weights(graph),
        heuristic::Function = (v -> zero(eltype(distmx))),
        edgetype_to_return = edgetype(graph)
    )
    coded_distmx = dist_matrix_to_coded_dist_matrix(graph, distmx)
    coded_shortest_path = a_star(
        coded_graph(graph),
        coded_vertex(graph, source),
        coded_vertex(graph, destination),
        dist_matrix_to_coded_dist_matrix(graph, distmx),
        heuristic,
        SimpleEdge
    )
    return map(e -> decoded_edge(graph, e), coded_shortest_path)
end

function Graphs.a_star(graph::AbstractNamedGraph, source, destination, args...)
    return namedgraph_a_star(graph, source, destination, args...)
end

# Fix ambiguity error with `AbstractGraph` version
function Graphs.a_star(
        graph::AbstractNamedGraph{U}, source::Integer, destination::Integer, args...
    ) where {U <: Integer}
    return namedgraph_a_star(graph, source, destination, args...)
end

# Fix ambiguity error with `AbstractGraph` version
function Graphs.a_star(
        graph::AbstractNamedGraph, source::Integer, destination::Integer, args...
    )
    return namedgraph_a_star(graph, source, destination, args...)
end

function Graphs.spfa_shortest_paths(
        graph::AbstractNamedGraph, vertex, distmx = weights(graph)
    )
    coded_distmx = dist_matrix_to_coded_dist_matrix(graph, distmx)
    coded_shortest_paths = spfa_shortest_paths(
        coded_graph(graph), coded_vertex(graph, vertex), coded_distmx
    )
    return dictionary(
        decoded_vertex(graph, c) => d for (c, d) in pairs(coded_shortest_paths)
    )
end

function Graphs.boruvka_mst(
        g::AbstractNamedGraph, distmx::AbstractMatrix{<:Real} = weights(g); minimize = true
    )
    coded_mst, weights = boruvka_mst(coded_graph(g), distmx; minimize)
    return map(e -> decoded_edge(g, e), coded_mst), weights
end

function Graphs.kruskal_mst(
        g::AbstractNamedGraph, distmx::AbstractMatrix{<:Real} = weights(g); minimize = true
    )
    coded_mst = kruskal_mst(coded_graph(g), distmx; minimize)
    return map(e -> decoded_edge(g, e), coded_mst)
end

function Graphs.prim_mst(g::AbstractNamedGraph, distmx::AbstractMatrix{<:Real} = weights(g))
    coded_mst = prim_mst(coded_graph(g), distmx)
    return map(e -> decoded_edge(g, e), coded_mst)
end

function Graphs.add_edge!(graph::AbstractNamedGraph, edge)
    add_edge!(coded_graph(graph), coded_edge(graph, edgetype(graph)(edge)))
    return graph
end
Graphs.add_edge!(g::AbstractNamedGraph, src, dst) = add_edge!(g, edgetype(g)(src, dst))

function Graphs.rem_edge!(graph::AbstractNamedGraph, edge)
    rem_edge!(coded_graph(graph), coded_edge(graph, edgetype(graph)(edge)))
    return graph
end

function Graphs.has_edge(graph::AbstractNamedGraph, edge::AbstractNamedEdge)
    has_vertex(graph, src(edge)) || return false
    has_vertex(graph, dst(edge)) || return false
    return has_edge(
        coded_graph(graph), coded_vertex(graph, src(edge)), coded_vertex(graph, dst(edge))
    )
end

# handles two-argument edge constructors like src,dst
Graphs.has_edge(g::AbstractNamedGraph, edge) = has_edge(g, edgetype(g)(edge))
Graphs.has_edge(g::AbstractNamedGraph, src, dst) = has_edge(g, edgetype(g)(src, dst))

function Graphs.has_path(
        graph::AbstractNamedGraph, source, destination; exclude_vertices = vertextype(graph)[]
    )
    return has_path(
        coded_graph(graph),
        coded_vertex(graph, source),
        coded_vertex(graph, destination);
        exclude_vertices = map(coded_vertex(graph), exclude_vertices)
    )
end

function Base.union(graph1::AbstractNamedGraph, graph2::AbstractNamedGraph)
    union_vertices = union(vertices(graph1), vertices(graph2))
    union_graph = similar_graph(graph1, union_vertices)

    for e in edges(graph1)
        add_edge!(union_graph, e)
    end
    for e in edges(graph2)
        add_edge!(union_graph, e)
    end
    return union_graph
end

function Base.union(
        graph1::AbstractNamedGraph,
        graph2::AbstractNamedGraph,
        graph3::AbstractNamedGraph,
        graph_rest::AbstractNamedGraph...
    )
    return union(union(graph1, graph2), graph3, graph_rest...)
end

function Graphs.is_directed(graph_type::Type{<:AbstractNamedGraph})
    return is_directed(coded_graph_type(graph_type))
end

Graphs.is_directed(graph::AbstractNamedGraph) = is_directed(coded_graph(graph))

Graphs.is_connected(graph::AbstractNamedGraph) = is_connected(coded_graph(graph))

Graphs.is_cyclic(graph::AbstractNamedGraph) = is_cyclic(coded_graph(graph))

@traitfn function Base.reverse(graph::AbstractNamedGraph::IsDirected)
    newgraph = edgeless_graph(graph)
    add_edges!(newgraph, map(reverse, edges(graph)))
    return newgraph
end

# This wont be the most efficient way for a given graph type.
@traitfn function Base.reverse!(g::AbstractNamedGraph::IsDirected)
    edge_list = collect(edges(g))

    for edge in edge_list
        rem_edge!(g, edge)
        add_edge!(g, reverse(edge))
    end

    return g
end

# TODO: Move to `namedgraph.jl`, or make the output generic?
function Graphs.blockdiag(graph1::AbstractNamedGraph, graph2::AbstractNamedGraph)
    new_coded_graph = blockdiag(coded_graph(graph1), coded_graph(graph2))
    new_vertices = vcat(
        map(decoded_vertex(graph1), vertices(coded_graph(graph1))),
        map(decoded_vertex(graph2), vertices(coded_graph(graph2)))
    )
    @assert allunique(new_vertices)
    return GenericNamedGraph(new_coded_graph, new_vertices)
end

Graphs.nv(graph::AbstractNamedGraph) = nv(coded_graph(graph))
Graphs.ne(graph::AbstractNamedGraph) = ne(coded_graph(graph))
function Graphs.adjacency_matrix(graph::AbstractNamedGraph)
    return adjacency_matrix(coded_graph(graph))
end

function Graphs.connected_components(graph::AbstractNamedGraph)
    coded_connected_components = connected_components(coded_graph(graph))
    return map(coded_connected_components) do coded_connected_component
        return map(decoded_vertex(graph), coded_connected_component)
    end
end

function Graphs.merge_vertices(
        graph::AbstractNamedGraph, merge_vertices; merged_vertex = first(merge_vertices)
    )
    merged_graph = copy(graph)
    add_vertex!(merged_graph, merged_vertex)
    for vertex in merge_vertices
        for e in incident_edges(graph, vertex; dir = :both)
            merged_edge = rename_vertices(v -> v == vertex ? merged_vertex : v, e)
            if src(merged_edge) ≠ dst(merged_edge)
                add_edge!(merged_graph, merged_edge)
            end
        end
    end
    for vertex in merge_vertices
        if vertex ≠ merged_vertex
            rem_vertex!(merged_graph, vertex)
        end
    end
    return merged_graph
end

#
# Graph traversals
#

# Overload Graphs.tree. Used for bfs_tree and dfs_tree
# traversal algorithms.
function Graphs.tree(graph::AbstractNamedGraph, parents)
    t = similar_graph(directed_graph(graph), vertices(graph))
    for destination in eachindex(parents)
        source = parents[destination]
        if source != destination
            add_edge!(t, source, destination)
        end
    end
    return t
end

function namedgraph_bfs_tree(graph::AbstractNamedGraph, vertex; kwargs...)
    return Graphs.tree(graph, bfs_parents(graph, vertex; kwargs...))
end
# Disambiguation from Graphs.bfs_tree
function Graphs.bfs_tree(graph::AbstractNamedGraph, vertex::Integer; kwargs...)
    return namedgraph_bfs_tree(graph, vertex; kwargs...)
end
function Graphs.bfs_tree(graph::AbstractNamedGraph, vertex; kwargs...)
    return namedgraph_bfs_tree(graph, vertex; kwargs...)
end

# Returns a Dictionary mapping a vertex to it's parent
# vertex in the traversal/spanning tree.
function namedgraph_bfs_parents(graph::AbstractNamedGraph, vertex; kwargs...)
    coded_bfs_parents = bfs_parents(
        coded_graph(graph), coded_vertex(graph, vertex); kwargs...
    )
    return dictionary(
        decoded_vertex(graph, c) => decoded_vertex(graph, p) for
            (c, p) in pairs(coded_bfs_parents)
    )
end
# Disambiguation from Graphs.jl
function Graphs.bfs_parents(graph::AbstractNamedGraph, vertex::Integer; kwargs...)
    return namedgraph_bfs_parents(graph, vertex; kwargs...)
end
function Graphs.bfs_parents(graph::AbstractNamedGraph, vertex; kwargs...)
    return namedgraph_bfs_parents(graph, vertex; kwargs...)
end

#
# Printing
#

function Base.show(io::IO, mime::MIME"text/plain", graph::AbstractNamedGraph)
    println(io, "$(typeof(graph)) with $(nv(graph)) vertices:")
    show(io, mime, vertices(graph))
    println(io, "\n")
    println(io, "and $(ne(graph)) edge(s):")
    show(io, mime, collect(edges(graph)))
    return nothing
end

Base.show(io::IO, graph::AbstractNamedGraph) = show(io, MIME"text/plain"(), graph)

#
# Convenience functions
#

function Base.:(==)(g1::AbstractNamedGraph, g2::AbstractNamedGraph)
    issetequal(vertices(g1), vertices(g2)) || return false
    for v in vertices(g1)
        issetequal(inneighbors(g1, v), inneighbors(g2, v)) || return false
        issetequal(outneighbors(g1, v), outneighbors(g2, v)) || return false
    end
    return true
end

function Graphs.induced_subgraph(graph::AbstractNamedGraph, subvertices)
    return induced_subgraph_namedgraph(graph, subvertices)
end
# For method ambiguity resolution with Graphs.jl
function Graphs.induced_subgraph(
        graph::AbstractNamedGraph, subvertices::AbstractVector{<:Integer}
    )
    return induced_subgraph_namedgraph(graph, subvertices)
end

function induced_subgraph_namedgraph(graph::AbstractGraph, subvertices)
    return induced_subgraph_from_vertices(graph, to_vertices(graph, subvertices))
end

# TODO: Implement an edgelist version
function induced_subgraph_from_vertices(graph::AbstractGraph, subvertices)
    subgraph = similar_graph(graph, subvertices)
    add_edges!(subgraph, subgraph_edges(graph, subvertices))
    return subgraph, nothing
end

function subgraph_edges(graph::AbstractGraph, subvertices)
    subvertices_set = Set(subvertices)
    return Iterators.filter(edges(graph)) do edge
        return src(edge) in subvertices_set && dst(edge) in subvertices_set
    end
end

function GraphsExtensions.edge_subgraph(graph::AbstractNamedGraph, edges)
    return edge_subgraph_namedgraph(graph, to_edges(graph, edges))
end
function GraphsExtensions.edge_subgraph(
        graph::AbstractNamedGraph,
        edges::Vector{<:AbstractEdge}
    )
    return edge_subgraph_namedgraph(graph, to_edges(graph, edges))
end

function edge_subgraph_namedgraph(graph, edgelist)
    vs = unique(vcat(src.(edgelist), dst.(edgelist)))
    g = subgraph(graph, vs)
    edgeset = Set(edgelist)
    # `collect` since `edges(g)` is a view of `g` and `g` is mutated in the loop.
    for e in collect(edges(g))
        if !(e ∈ edgeset || reverse(e) ∈ edgeset)
            rem_edge!(g, e)
        end
    end
    return g
end
