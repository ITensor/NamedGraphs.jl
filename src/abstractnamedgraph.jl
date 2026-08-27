using .GraphsExtensions: GraphsExtensions, all_edges, directed_graph, empty_graph,
    incident_edges, partition_vertices, rem_edges, rem_edges!, rem_vertices, similar_graph,
    subgraph
using Dictionaries: Dictionary, set!
using Graphs: Graphs, AbstractGraph, AbstractSimpleGraph, IsDirected, SimpleDiGraph,
    SimpleEdge, SimpleGraph, a_star, add_edge!, adjacency_matrix, bfs_parents, blockdiag,
    boruvka_mst, connected_components, degree, edges, has_path, indegree, induced_subgraph,
    inneighbors, is_connected, is_cyclic, kruskal_mst, ne, neighborhood, neighborhood_dists,
    nv, outdegree, prim_mst, rem_edge!, spfa_shortest_paths, vertices, weights
using SimpleTraits: SimpleTraits, @traitfn, Not

"""
    AbstractNamedGraph{V} <: Graphs.AbstractGraph{V}

Abstract type for graphs whose vertices are names of type `V` rather than
contiguous integers. Subtypes implement the Graphs.jl interface in terms of a
graph on integer vertex codes through the minimal interface
[`encoded_graph`](@ref), [`encode_vertex`](@ref), and [`decode_vertex`](@ref).
"""
abstract type AbstractNamedGraph{V} <: AbstractGraph{V} end

#
# Required for interface
#

"""
    encode_vertex(graph::AbstractNamedGraph, vertex) -> Int

The code of `vertex` in `graph`, i.e. the corresponding vertex of
[`encoded_graph(graph)`](@ref encoded_graph). `encode_vertex(graph, ·)` and
[`decode_vertex(graph, ·)`](@ref decode_vertex) are inverse bijections between
`vertices(graph)` and `Base.OneTo(nv(graph))`.

Codes are not stable across mutation: adding or removing vertices may reassign
the codes of other vertices.

# Examples

```jldoctest
julia> using Graphs: path_graph

julia> using NamedGraphs: NamedGraph, decode_vertex, encode_vertex

julia> g = NamedGraph(path_graph(3), ["a", "b", "c"]);

julia> encode_vertex(g, "b")
2

julia> decode_vertex(g, 2)
"b"
```
"""
encode_vertex(graph::AbstractNamedGraph, vertex) = not_implemented()
encode_vertex(graph::AbstractSimpleGraph, vertex) = vertex

"""
    decode_vertex(graph::AbstractNamedGraph, code::Integer)

The vertex of `graph` whose code is `code`, i.e. the vertex corresponding to the
vertex `code` of [`encoded_graph(graph)`](@ref encoded_graph). Inverse of
[`encode_vertex`](@ref).

# Examples

```jldoctest
julia> using Graphs: nv, path_graph

julia> using NamedGraphs: NamedGraph, decode_vertex

julia> g = NamedGraph(path_graph(3), ["a", "b", "c"]);

julia> [decode_vertex(g, c) for c in 1:nv(g)]
3-element Vector{String}:
 "a"
 "b"
 "c"
```
"""
decode_vertex(graph::AbstractNamedGraph, code::Integer) = not_implemented()
decode_vertex(graph::AbstractSimpleGraph, code::Integer) = code

Graphs.rem_vertex!(graph::AbstractNamedGraph, vertex) = not_implemented()
Graphs.add_vertex!(graph::AbstractNamedGraph, vertex) = not_implemented()

function rename_vertices(f::Function, graph::AbstractNamedGraph)
    new_vertices = map(c -> f(decode_vertex(graph, c)), vertices(encoded_graph(graph)))
    return namedgraph(copy(encoded_graph(graph)), new_vertices)
end

#
# Derived interface (overload for performance)
#

"""
    encoded_graph(graph::AbstractNamedGraph) -> AbstractGraph{Int}

The graph in coded form: a graph with the same topology as `graph` whose
vertices are the codes `1:nv(graph)` of the vertices of `graph`, i.e. it has
the edge `encode_vertex(graph, u) => encode_vertex(graph, v)` if and only if
`graph` has the edge `u => v`.

May be a stored field or a view of `graph`; mutate the graph only through
`graph`.

# Examples

```jldoctest
julia> using Graphs: edges, has_edge, path_graph, vertices

julia> using NamedGraphs: NamedGraph, encode_vertex, encoded_graph

julia> g = NamedGraph(path_graph(3), ["a", "b", "c"]);

julia> cg = encoded_graph(g)
{3, 2} undirected simple Int64 graph

julia> vertices(cg)
Base.OneTo(3)

julia> collect(edges(cg))
2-element Vector{Graphs.SimpleGraphs.SimpleEdge{Int64}}:
 Edge 1 => 2
 Edge 2 => 3

julia> encode_vertex(g, "a"), encode_vertex(g, "b")
(1, 2)

julia> has_edge(cg, 1, 2)
true
```
"""
encoded_graph(graph::AbstractNamedGraph) = EncodedGraphView(graph)
encoded_graph(graph::AbstractSimpleGraph) = graph

"""
    vertices(graph::AbstractNamedGraph) -> Dictionaries.AbstractIndices

The set of vertices of `graph`: a `Dictionaries.AbstractIndices` containing each
vertex exactly once, with fast membership testing. See
[Dictionaries.jl](https://github.com/andyferris/Dictionaries.jl) for that
interface.

The vertices iterate in insertion order: they appear in the order they were
added to the graph, removing a vertex does not reorder the rest, and added
vertices appear at the end. The iteration order therefore does not in general
match the vertex codes after removals, since codes are reassigned. Use
`decode_vertex` for the vertices in code order, for example
`map(c -> decode_vertex(graph, c), 1:nv(graph))`.

The output is a live read-only view of the graph: do not mutate it directly,
and do not rely on it (or containers sharing its state) across mutations of
the graph.

# Examples

Removing a vertex does not reorder the rest, but it does reassign codes, so the
two orders come apart:

```jldoctest
julia> using Graphs: nv, path_graph, rem_vertex!, vertices

julia> using NamedGraphs: NamedGraph, decode_vertex

julia> g = NamedGraph(path_graph(4), ["v1", "v2", "v3", "v4"]);

julia> rem_vertex!(g, "v2");

julia> collect(vertices(g))
3-element Vector{String}:
 "v1"
 "v3"
 "v4"

julia> [decode_vertex(g, c) for c in 1:nv(g)]
3-element Vector{String}:
 "v1"
 "v4"
 "v3"
```
"""
Graphs.vertices(graph::AbstractNamedGraph) = NamedVerticesView(graph)

# TODO: Is this a good definition? Maybe make it generic to any graph?
function GraphsExtensions.permute_vertices(graph::AbstractNamedGraph, permutation)
    return subgraph(graph, map(c -> decode_vertex(graph, c), permutation))
end

Graphs.edgetype(graph::AbstractNamedGraph) = edgetype(typeof(graph))
function Graphs.edgetype(graph_type::Type{<:AbstractNamedGraph})
    return NamedEdge{vertextype(graph_type)}
end

# In terms of `encoded_graph_type`
# is_directed(::Type{<:AbstractNamedGraph}) = not_implemented()

GraphsExtensions.convert_vertextype(::Type{V}, g::AbstractNamedGraph{V}) where {V} = g
function GraphsExtensions.convert_vertextype(vertextype::Type, graph::AbstractNamedGraph)
    new_vertices = map(c -> decode_vertex(graph, c), vertices(encoded_graph(graph)))
    return namedgraph(copy(encoded_graph(graph)), convert(Vector{vertextype}, new_vertices))
end

# `similar_graph(graph)` copies the vertices and edges.
Base.copy(graph::AbstractNamedGraph) = similar_graph(graph)

function Graphs.merge_vertices!(
        graph::AbstractNamedGraph, merge_vertices; merged_vertex = first(merge_vertices)
    )
    return not_implemented()
end

#
# Derived interface
#

encoded_graph_type(graph::AbstractNamedGraph) = typeof(encoded_graph(graph))
encoded_graph_type(T::Type{<:AbstractNamedGraph}) = Base.promote_op(encoded_graph, T)

function Graphs.has_vertex(graph::AbstractNamedGraph, vertex)
    return vertex ∈ vertices(graph)
end

Graphs.SimpleDiGraph(graph::AbstractNamedGraph) = SimpleDiGraph(encoded_graph(graph))

Base.zero(G::Type{<:AbstractNamedGraph}) = G()

# Default, can overload
Base.eltype(graph::AbstractNamedGraph) = eltype(vertices(graph))

"""
    encode_edge(graph::AbstractNamedGraph, edge) -> AbstractEdge{Int}

The edge of [`encoded_graph(graph)`](@ref encoded_graph) corresponding to `edge`,
i.e. the edge between the codes of the vertices of `edge`.
Inverse of [`decode_edge`](@ref).

# Examples

```jldoctest
julia> using Graphs: path_graph

julia> using NamedGraphs: NamedEdge, NamedGraph, decode_edge, encode_edge

julia> g = NamedGraph(path_graph(3), ["a", "b", "c"]);

julia> ce = encode_edge(g, NamedEdge("a" => "b"))
Edge 1 => 2

julia> decode_edge(g, ce)
"a" => "b"
```
"""
function encode_edge(graph::AbstractNamedGraph, edge::AbstractEdge)
    return edgetype(encoded_graph(graph))(
        encode_vertex(graph, src(edge)), encode_vertex(graph, dst(edge))
    )
end

"""
    decode_edge(graph::AbstractNamedGraph, encoded_edge)

The edge of `graph` corresponding to the edge `encoded_edge` of
[`encoded_graph(graph)`](@ref encoded_graph). Inverse of [`encode_edge`](@ref).
"""
function decode_edge(graph::AbstractNamedGraph, encoded_edge::AbstractEdge)
    return edgetype(graph)(
        decode_vertex(graph, src(encoded_edge)),
        decode_vertex(graph, dst(encoded_edge))
    )
end

"""
    edges(graph::AbstractNamedGraph) -> AbstractEdgeIter

A Graphs.jl `AbstractEdgeIter` over the edges of `graph`, yielding each edge
exactly once, with membership testing (`in`) matching `has_edge` (in particular,
on undirected graphs an edge and its reverse are both members while iteration
yields each edge once). The iteration order is unspecified.

The output is a live view of the graph: do not rely on it across mutations of
the graph.

# Examples

```jldoctest
julia> using Graphs: edges, path_graph

julia> using NamedGraphs: NamedEdge, NamedGraph

julia> g = NamedGraph(path_graph(3), ["a", "b", "c"]);

julia> collect(edges(g))
2-element Vector{NamedEdge{String}}:
 "a" => "b"
 "b" => "c"

julia> NamedEdge("b" => "a") in edges(g)
true
```
"""
Graphs.edges(graph::AbstractNamedGraph) = NamedEdgeIter(graph)

# Graphs.jl declares these with an `::Integer` vertex, which ties with an
# untyped vertex argument on a graph whose vertices are integers. Both forms are
# therefore defined here, once, and both forward to an `f_namedgraph` hook.
# Subtypes override the hook rather than the Graphs.jl function, so they never
# add a method to a function upstream also defines on `::Integer` and never need
# an `::Integer` disambiguator of their own.
for f in [:outneighbors, :inneighbors, :all_neighbors, :neighbors]
    f_namedgraph = Symbol(f, :_namedgraph)
    @eval begin
        function $f_namedgraph(graph::AbstractNamedGraph, vertex)
            encoded_neighbors =
                Graphs.$f(encoded_graph(graph), encode_vertex(graph, vertex))
            return map(c -> decode_vertex(graph, c), encoded_neighbors)
        end

        Graphs.$f(graph::AbstractNamedGraph, vertex) = $f_namedgraph(graph, vertex)
        Graphs.$f(graph::AbstractNamedGraph, vertex::Integer) = $f_namedgraph(graph, vertex)
    end
end

function Graphs.common_neighbors(g::AbstractNamedGraph, u, v)
    return intersect(neighbors(g, u), neighbors(g, v))
end

# Mirrors the `AbstractGraph` signature in Graphs.jl so the wrapper above is
# not ambiguous with it.
function Graphs.common_neighbors(g::AbstractNamedGraph, u::Integer, v::Integer)
    return intersect(neighbors(g, u), neighbors(g, v))
end

indegree_namedgraph(graph::AbstractNamedGraph, vertex) = length(inneighbors(graph, vertex))
function outdegree_namedgraph(graph::AbstractNamedGraph, vertex)
    return length(outneighbors(graph, vertex))
end

Graphs.indegree(graph::AbstractNamedGraph, vertex) = indegree_namedgraph(graph, vertex)
Graphs.outdegree(graph::AbstractNamedGraph, vertex) = outdegree_namedgraph(graph, vertex)

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.indegree(graph::AbstractNamedGraph, vertex::Integer)
    return indegree_namedgraph(graph, vertex)
end
function Graphs.outdegree(graph::AbstractNamedGraph, vertex::Integer)
    return outdegree_namedgraph(graph, vertex)
end

@traitfn function degree_namedgraph(graph::AbstractNamedGraph::IsDirected, vertex)
    return indegree(graph, vertex) + outdegree(graph, vertex)
end
@traitfn degree_namedgraph(graph::AbstractNamedGraph::(!IsDirected), vertex) = indegree(
    graph, vertex
)

function Graphs.degree(graph::AbstractNamedGraph, vertex)
    return degree_namedgraph(graph::AbstractNamedGraph, vertex)
end

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.degree(graph::AbstractNamedGraph, vertex::Integer)
    return degree_namedgraph(graph::AbstractNamedGraph, vertex)
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

function neighborhood_namedgraph(
        graph::AbstractNamedGraph, vertex, d, distmx = weights(graph); dir = :out
    )
    encoded_distmx = encode_dist_matrix(graph, distmx)
    encoded_neighborhood = neighborhood(
        encoded_graph(graph), encode_vertex(graph, vertex), d, encoded_distmx; dir
    )
    return [decode_vertex(graph, c) for c in encoded_neighborhood]
end

function Graphs.neighborhood(
        graph::AbstractNamedGraph, vertex, d, distmx = weights(graph); dir = :out
    )
    return neighborhood_namedgraph(graph, vertex, d, distmx; dir)
end

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.neighborhood(
        graph::AbstractNamedGraph, vertex::Integer, d, distmx = weights(graph); dir = :out
    )
    return neighborhood_namedgraph(graph, vertex, d, distmx; dir)
end

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.neighborhood(
        graph::AbstractNamedGraph, vertex::Integer, d, distmx::AbstractMatrix{<:Real};
        dir = :out
    )
    return neighborhood_namedgraph(graph, vertex, d, distmx; dir)
end

function neighborhood_dists_namedgraph(graph::AbstractNamedGraph, vertex, d, distmx; dir)
    encoded_distmx = encode_dist_matrix(graph, distmx)
    encoded_vertices_and_dists = neighborhood_dists(
        encoded_graph(graph), encode_vertex(graph, vertex), d, encoded_distmx; dir
    )
    return [
        (decode_vertex(graph, c), dist) for (c, dist) in encoded_vertices_and_dists
    ]
end

function Graphs.neighborhood_dists(
        graph::AbstractNamedGraph, vertex, d, distmx = weights(graph); dir = :out
    )
    return neighborhood_dists_namedgraph(graph, vertex, d, distmx; dir)
end

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.neighborhood_dists(
        graph::AbstractNamedGraph, vertex::Integer, d, distmx = weights(graph); dir = :out
    )
    return neighborhood_dists_namedgraph(graph, vertex, d, distmx; dir)
end

# Fix for ambiguity error with `AbstractGraph` version
function Graphs.neighborhood_dists(
        graph::AbstractNamedGraph, vertex::Integer, d, distmx::AbstractMatrix{<:Real};
        dir = :out
    )
    return neighborhood_dists_namedgraph(graph, vertex, d, distmx; dir)
end

function mincut_namedgraph(graph::AbstractNamedGraph, distmx)
    encoded_distmx = encode_dist_matrix(graph, distmx)
    encoded_parity, bestcut = Graphs.mincut(encoded_graph(graph), encoded_distmx)
    graph_vertices = map(c -> decode_vertex(graph, c), vertices(encoded_graph(graph)))
    return Dictionary(graph_vertices, encoded_parity), bestcut
end

function Graphs.mincut(graph::AbstractNamedGraph, distmx = weights(graph))
    return mincut_namedgraph(graph, distmx)
end

# Mirrors the `AbstractGraph` signature in Graphs.jl so the wrapper above is
# not ambiguous with it.
# The bound matches Graphs.jl exactly: widening `<:Number` to `<:Real` here
# would leave `Complex` distance matrices ambiguous.
function Graphs.mincut(graph::AbstractNamedGraph, distmx::AbstractMatrix{<:Number})
    return mincut_namedgraph(graph, distmx)
end

# TODO: Make this more generic?
function GraphsExtensions.partition_vertices(
        graph::AbstractNamedGraph; npartitions = nothing, nvertices_per_partition = nothing,
        kwargs...
    )
    vertex_partitions = partition_vertices(
        encoded_graph(graph); npartitions, nvertices_per_partition, kwargs...
    )
    # TODO: output the reverse of this dictionary (a Vector of Vector
    # of the vertices in each partition).
    # return Dictionary(vertices(g), partitions)
    return map(vertex_partitions) do vertex_partition
        return map(c -> decode_vertex(graph, c), vertex_partition)
    end
end

function a_star_namedgraph(
        graph::AbstractNamedGraph,
        source,
        destination,
        distmx = weights(graph),
        heuristic = (v -> zero(eltype(distmx))),
        edgetype_to_return = edgetype(graph)
    )
    encoded_shortest_path = a_star(
        encoded_graph(graph),
        encode_vertex(graph, source),
        encode_vertex(graph, destination),
        encode_dist_matrix(graph, distmx),
        heuristic,
        # The encoded graph has integer vertices, so the inner search returns
        # `SimpleEdge`s regardless of the edge type requested for the output.
        SimpleEdge
    )
    return map(encoded_shortest_path) do encoded_edge
        edge = decode_edge(graph, encoded_edge)
        # Build from the endpoints rather than converting, so edge types other
        # than `edgetype(graph)` do not need a constructor taking a `NamedEdge`.
        return edgetype_to_return(src(edge), dst(edge))
    end
end

function Graphs.a_star(
        graph::AbstractNamedGraph,
        source,
        destination,
        distmx = weights(graph),
        heuristic = (v -> zero(eltype(distmx))),
        edgetype_to_return = edgetype(graph)
    )
    return a_star_namedgraph(
        graph, source, destination, distmx, heuristic, edgetype_to_return
    )
end

# Mirrors the `AbstractGraph` signature in Graphs.jl so the wrapper above is not
# ambiguous with it. `distmx` is left unbounded because Graphs.jl does not
# constrain its element type here.
function Graphs.a_star(
        graph::AbstractNamedGraph,
        source::Integer,
        destination::Integer,
        distmx::AbstractMatrix = weights(graph),
        heuristic = (v -> zero(eltype(distmx))),
        edgetype_to_return::Type{<:AbstractEdge} = edgetype(graph)
    )
    return a_star_namedgraph(
        graph, source, destination, distmx, heuristic, edgetype_to_return
    )
end

function spfa_shortest_paths_namedgraph(graph::AbstractNamedGraph, vertex, distmx)
    encoded_distmx = encode_dist_matrix(graph, distmx)
    encoded_shortest_paths = spfa_shortest_paths(
        encoded_graph(graph), encode_vertex(graph, vertex), encoded_distmx
    )
    graph_vertices = map(c -> decode_vertex(graph, c), vertices(encoded_graph(graph)))
    return Dictionary(graph_vertices, encoded_shortest_paths)
end

function Graphs.spfa_shortest_paths(
        graph::AbstractNamedGraph, vertex, distmx = weights(graph)
    )
    return spfa_shortest_paths_namedgraph(graph, vertex, distmx)
end

# Mirrors the `AbstractGraph` signature in Graphs.jl so the wrapper above is
# not ambiguous with it.
function Graphs.spfa_shortest_paths(
        graph::AbstractNamedGraph,
        vertex::Integer,
        distmx::AbstractMatrix{<:Number} = weights(graph)
    )
    return spfa_shortest_paths_namedgraph(graph, vertex, distmx)
end

function Graphs.boruvka_mst(
        g::AbstractNamedGraph, distmx::AbstractMatrix{<:Real} = weights(g); minimize = true
    )
    encoded_mst, weights = boruvka_mst(encoded_graph(g), distmx; minimize)
    return map(e -> decode_edge(g, e), encoded_mst), weights
end

function Graphs.kruskal_mst(
        g::AbstractNamedGraph, distmx::AbstractMatrix{<:Real} = weights(g); minimize = true
    )
    encoded_mst = kruskal_mst(encoded_graph(g), distmx; minimize)
    return map(e -> decode_edge(g, e), encoded_mst)
end

function Graphs.prim_mst(g::AbstractNamedGraph, distmx::AbstractMatrix{<:Real} = weights(g))
    encoded_mst = prim_mst(encoded_graph(g), distmx)
    return map(e -> decode_edge(g, e), encoded_mst)
end

function Graphs.add_edge!(graph::AbstractNamedGraph, edge)
    e = edgetype(graph)(edge)
    has_vertex(graph, src(e)) || return false
    has_vertex(graph, dst(e)) || return false
    return add_edge!(encoded_graph(graph), encode_edge(graph, e))
end
Graphs.add_edge!(g::AbstractNamedGraph, src, dst) = add_edge!(g, edgetype(g)(src, dst))

# Hook so the `::Integer` disambiguator below does not repeat the body. The name
# is `Symbol(f, :_namedgraph)` like the other hooks, keeping the bang where the
# function name has it rather than special-casing mutating functions.
function add_vertices!_namedgraph(graph::AbstractNamedGraph, vs)
    return count(v -> add_vertex!(graph, v), vs)
end

"""
    add_vertices!(graph::AbstractNamedGraph, vs)

Add the vertices `vs` to `graph` in place, returning how many were added. A vertex
already in `graph` is not added and does not count.

This is a method of `Graphs.add_vertices!`, whose other form takes a count of
vertices to append. A named graph cannot invent names, so an integer here is a
vertex name rather than a count.
"""
Graphs.add_vertices!(graph::AbstractNamedGraph, vs) = add_vertices!_namedgraph(graph, vs)
# Disambiguates against `Graphs.add_vertices!(::AbstractGraph, ::Integer)`, whose
# integer is a count of vertices to append. A named graph cannot invent names, so
# that reading is undefined here and the integer is a vertex name instead, as
# everywhere else an integer sits in a vertex position. Deliberately not an error:
# an integer in a vertex position is a name throughout this interface, and making
# this one spelling the exception would be the surprise.
function Graphs.add_vertices!(graph::AbstractNamedGraph, vertex::Integer)
    return add_vertices!_namedgraph(graph, (vertex,))
end

function rem_vertices!_namedgraph(graph::AbstractNamedGraph, vs)
    return count(v -> rem_vertex!(graph, v), vs)
end

"""
    rem_vertices!(graph::AbstractNamedGraph, vs)

Remove the vertices `vs` from `graph` in place, along with their incident edges,
returning how many were removed. A vertex not in `graph` does not count.

This is a method of `Graphs.rem_vertices!`, and it deliberately differs from the
`Graphs.SimpleGraph` and `SimpleDiGraph` methods, the only ones Graphs.jl
provides, which throw for a vertex outside `1:nv(graph)` and return a vector
mapping new vertex labels back to old ones. Named vertices are
stable under removal, so there is nothing to map, and a name that is not present
is simply not removed.
"""
Graphs.rem_vertices!(graph::AbstractNamedGraph, vs) = rem_vertices!_namedgraph(graph, vs)

function Graphs.rem_edge!(graph::AbstractNamedGraph, edge)
    e = edgetype(graph)(edge)
    has_vertex(graph, src(e)) || return false
    has_vertex(graph, dst(e)) || return false
    return rem_edge!(encoded_graph(graph), encode_edge(graph, e))
end

function Graphs.has_edge(graph::AbstractNamedGraph, edge::AbstractNamedEdge)
    has_vertex(graph, src(edge)) || return false
    has_vertex(graph, dst(edge)) || return false
    return has_edge(
        encoded_graph(graph), encode_vertex(graph, src(edge)),
        encode_vertex(graph, dst(edge))
    )
end

# handles two-argument edge constructors like src,dst
Graphs.has_edge(g::AbstractNamedGraph, edge) = has_edge(g, edgetype(g)(edge))
Graphs.has_edge(g::AbstractNamedGraph, src, dst) = has_edge(g, edgetype(g)(src, dst))

function has_path_namedgraph(
        graph::AbstractNamedGraph,
        source,
        destination,
        exclude_vertices
    )
    return has_path(
        encoded_graph(graph),
        encode_vertex(graph, source),
        encode_vertex(graph, destination);
        exclude_vertices = map(v -> encode_vertex(graph, v), exclude_vertices)
    )
end

function Graphs.has_path(
        graph::AbstractNamedGraph, source, destination; exclude_vertices = vertextype(graph)[]
    )
    return has_path_namedgraph(graph, source, destination, exclude_vertices)
end

# Mirrors the `AbstractGraph` signature in Graphs.jl so the wrapper above is
# not ambiguous with it.
function Graphs.has_path(
        graph::AbstractNamedGraph,
        source::Integer,
        destination::Integer;
        exclude_vertices = vertextype(graph)[]
    )
    return has_path_namedgraph(graph, source, destination, exclude_vertices)
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
    return is_directed(encoded_graph_type(graph_type))
end

Graphs.is_directed(graph::AbstractNamedGraph) = is_directed(encoded_graph(graph))

Graphs.is_connected(graph::AbstractNamedGraph) = is_connected(encoded_graph(graph))

Graphs.is_cyclic(graph::AbstractNamedGraph) = is_cyclic(encoded_graph(graph))

function Base.reverse(graph::AbstractNamedGraph)
    new_vertices = map(c -> decode_vertex(graph, c), vertices(encoded_graph(graph)))
    return namedgraph(reverse(encoded_graph(graph)), new_vertices)
end

function Base.reverse!(graph::AbstractNamedGraph)
    reverse!(encoded_graph(graph))
    return graph
end

function Graphs.blockdiag(graph1::AbstractNamedGraph, graph2::AbstractNamedGraph)
    new_encoded_graph = blockdiag(encoded_graph(graph1), encoded_graph(graph2))
    new_vertices = vcat(
        map(c -> decode_vertex(graph1, c), vertices(encoded_graph(graph1))),
        map(c -> decode_vertex(graph2, c), vertices(encoded_graph(graph2)))
    )
    @assert allunique(new_vertices)
    return namedgraph(new_encoded_graph, new_vertices)
end

Graphs.nv(graph::AbstractNamedGraph) = nv(encoded_graph(graph))
Graphs.ne(graph::AbstractNamedGraph) = ne(encoded_graph(graph))
function Graphs.adjacency_matrix(graph::AbstractNamedGraph)
    return adjacency_matrix(encoded_graph(graph))
end

function Graphs.connected_components(graph::AbstractNamedGraph)
    encoded_connected_components = connected_components(encoded_graph(graph))
    return map(encoded_connected_components) do encoded_connected_component
        return map(c -> decode_vertex(graph, c), encoded_connected_component)
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

function bfs_tree_namedgraph(graph::AbstractNamedGraph, vertex; kwargs...)
    return Graphs.tree(graph, bfs_parents(graph, vertex; kwargs...))
end
# Disambiguation from Graphs.bfs_tree
function Graphs.bfs_tree(graph::AbstractNamedGraph, vertex::Integer; kwargs...)
    return bfs_tree_namedgraph(graph, vertex; kwargs...)
end
function Graphs.bfs_tree(graph::AbstractNamedGraph, vertex; kwargs...)
    return bfs_tree_namedgraph(graph, vertex; kwargs...)
end

# Returns a Dictionary mapping a vertex to it's parent
# vertex in the traversal/spanning tree.
function bfs_parents_namedgraph(graph::AbstractNamedGraph, vertex; kwargs...)
    encoded_bfs_parents = bfs_parents(
        encoded_graph(graph), encode_vertex(graph, vertex); kwargs...
    )
    graph_vertices = map(c -> decode_vertex(graph, c), vertices(encoded_graph(graph)))
    # Unreachable vertices have parent code 0; map them to themselves like
    # `dijkstra_shortest_paths` does.
    parents = map(eachindex(encoded_bfs_parents)) do c
        p = encoded_bfs_parents[c]
        return decode_vertex(graph, iszero(p) ? c : p)
    end
    return Dictionary(graph_vertices, parents)
end
# Disambiguation from Graphs.jl
function Graphs.bfs_parents(graph::AbstractNamedGraph, vertex::Integer; kwargs...)
    return bfs_parents_namedgraph(graph, vertex; kwargs...)
end
function Graphs.bfs_parents(graph::AbstractNamedGraph, vertex; kwargs...)
    return bfs_parents_namedgraph(graph, vertex; kwargs...)
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
# Mirrors the `AbstractGraph` signatures in Graphs.jl so the wrapper above is
# not ambiguous with them.
function Graphs.induced_subgraph(
        graph::AbstractNamedGraph, subvertices::AbstractVector{<:Integer}
    )
    return induced_subgraph_namedgraph(graph, subvertices)
end
function Graphs.induced_subgraph(
        graph::AbstractNamedGraph, edgelist::AbstractVector{<:AbstractEdge}
    )
    return edge_subgraph_namedgraph(graph, to_edges(graph, edgelist)), nothing
end
# Graphs.jl reads a `Vector{Bool}` as a mask over `1:nv(graph)`. That is
# position-dependent, and a named graph does not promise any correspondence
# between a vertex's position and its name, so here it is a list of vertex
# names like any other, which happen to be `Bool`s.
function Graphs.induced_subgraph(
        graph::AbstractNamedGraph, subvertices::AbstractVector{Bool}
    )
    return induced_subgraph_namedgraph(graph, subvertices)
end

function induced_subgraph_namedgraph(graph::AbstractGraph, subvertices)
    return induced_subgraph_from_vertices(graph, to_vertices(graph, subvertices))
end

function induced_subgraph_from_vertices(graph::AbstractGraph, subvertices)
    # `subvertices` is an arbitrary iterable here (`to_vertices` wraps vectors in
    # `Vertices`, which is not an `AbstractArray`), so this avoids `filter` and
    # only builds the list of offenders when there is something to report.
    if any(v -> v ∉ vertices(graph), subvertices)
        unknown_vertices = [v for v in subvertices if v ∉ vertices(graph)]
        throw(
            ArgumentError(
                "Can't take the subgraph induced by vertices that aren't in the graph: $(unknown_vertices)."
            )
        )
    end
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
