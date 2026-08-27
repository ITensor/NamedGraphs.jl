using .GraphsExtensions: GraphsExtensions, similar_graph, similar_simplegraph, vertextype
using Dictionaries: Dictionary
using Graphs.SimpleGraphs: AbstractSimpleGraph, SimpleDiGraph, SimpleGraph
using Graphs: Graphs, AbstractGraph, IsDirected, add_edge!, add_vertex!, edgetype, has_edge,
    is_directed, outneighbors, rem_vertex!, vertices
using SimpleTraits: SimpleTraits, @traitfn, Not

to_vertices(graph, vertices) = _to_vertices(graph, vertices)
_to_vertices(::AbstractSimpleGraph, vertices) = to_vertices(vertices)
_to_vertices(::AbstractGraph, vertices) = vertices

to_vertices(vertices) = vertices
to_vertices(vertices::AbstractArray) = vec(vertices)
to_vertices(vertices::Integer) = Base.OneTo(vertices)

for (T, GT) in ((:NamedGraph, :SimpleGraph), (:NamedDiGraph, :SimpleDiGraph))
    @eval begin
        struct $T{V} <: AbstractNamedGraph{V}
            encoded_graph::$GT{Int}
            decoded_vertices::Vector{V}
            encoded_vertices::Dictionary{V, Int}
            function $T{V}(graph::AbstractSimpleGraph, vertices) where {V}
                encoded_graph = encoded_graph_type($T)(graph)
                decoded_vertices = collect(V, to_vertices(encoded_graph, vertices))
                @assert length(decoded_vertices) == nv(encoded_graph)
                # `copy` since the `Dictionary` takes ownership of the key vector,
                # which would otherwise alias the `decoded_vertices` field.
                encoded_vertices =
                    Dictionary{V, Int}(copy(decoded_vertices), eachindex(decoded_vertices))
                return new{V}(encoded_graph, decoded_vertices, encoded_vertices)
            end
        end

        # AbstractNamedGraph required interface.
        encoded_graph_type(graph_type::Type{<:$T}) = $GT{Int}
    end
end

for T in (:NamedGraph, :NamedDiGraph)
    @eval begin
        encoded_graph(graph::$T) = graph.encoded_graph
        encode_vertex(graph::$T, vertex) = graph.encoded_vertices[vertex]
        decode_vertex(graph::$T, code::Integer) = graph.decoded_vertices[code]

        Graphs.vertices(graph::$T) = keys(graph.encoded_vertices)

        function Graphs.add_vertex!(graph::$T, vertex)
            if vertex ∈ vertices(graph)
                return false
            end
            # `add_vertex!` on the encoded graph fails if the code type is out of
            # space, which must not leave a name mapped to a nonexistent code.
            add_vertex!(encoded_graph(graph)) || return false
            push!(graph.decoded_vertices, vertex)
            insert!(graph.encoded_vertices, vertex, nv(encoded_graph(graph)))
            return true
        end

        function Graphs.rem_vertex!(graph::$T, vertex)
            if vertex ∉ vertices(graph)
                return false
            end
            code = encode_vertex(graph, vertex)
            # `rem_vertex!` on an `AbstractSimpleGraph` moves the last vertex into
            # the removed slot, so mirror that reassignment in the vertex-code maps.
            rem_vertex!(encoded_graph(graph), code)
            last_vertex = pop!(graph.decoded_vertices)
            delete!(graph.encoded_vertices, vertex)
            if vertex ≠ last_vertex
                graph.decoded_vertices[code] = last_vertex
                graph.encoded_vertices[last_vertex] = code
            end
            return true
        end

        # Constructors from `AbstractSimpleGraph`.
        function $T{V}(simple_graph::AbstractSimpleGraph) where {V}
            return $T{V}(simple_graph, vertices(simple_graph))
        end
        function $T(simple_graph::AbstractSimpleGraph, vertices)
            return $T{eltype(vertices)}(simple_graph, vertices)
        end
        $T(simple_graph::AbstractSimpleGraph) = $T(simple_graph, vertices(simple_graph))

        # Constructors from vertex names.
        function $T{V}(vertices) where {V}
            return $T{V}(encoded_graph_type($T)(length(to_vertices(vertices))), vertices)
        end
        $T(vertices) = $T{eltype(vertices)}(vertices)

        # Empty constructors.
        $T{V}() where {V} = $T{V}(V[])
        $T() = $T(Any[])

        # Conversions.
        $T{V}(graph::$T{V}) where {V} = copy(graph)
        function $T{V}(graph::$T) where {V}
            return $T{V}(copy(encoded_graph(graph)), copy(graph.decoded_vertices))
        end
        $T(graph::$T) = $T{vertextype(graph)}(graph)
        Base.convert(graph_type::Type{<:$T}, graph::$T) = graph_type(graph)
    end
end

"""
    NamedGraph{V}
    NamedGraph(vertices)
    NamedGraph(simple_graph::AbstractSimpleGraph, vertices)

An undirected graph whose vertices are the names in `vertices`, backed by a
`Graphs.SimpleGraph` on the integer vertex codes. When constructed from a
simple graph, the `i`th name corresponds to the vertex `i` of `simple_graph`,
and otherwise the graph starts with no edges.

# Examples

```jldoctest
julia> using Graphs: add_edge!, has_edge, ne, nv, path_graph

julia> using NamedGraphs: NamedGraph

julia> g = NamedGraph(["a", "b", "c", "d"]);

julia> add_edge!(g, "a" => "b")
true

julia> has_edge(g, "b", "a")
true

julia> g = NamedGraph(path_graph(4), ["a", "b", "c", "d"]);

julia> (nv(g), ne(g))
(4, 3)
```
"""
NamedGraph

"""
    NamedDiGraph{V}
    NamedDiGraph(vertices)
    NamedDiGraph(simple_graph::AbstractSimpleGraph, vertices)

A directed graph whose vertices are the names in `vertices`, backed by a
`Graphs.SimpleDiGraph` on the integer vertex codes. When constructed from a
simple graph, the `i`th name corresponds to the vertex `i` of `simple_graph`,
and otherwise the graph starts with no edges.

# Examples

```jldoctest
julia> using Graphs: add_edge!, has_edge

julia> using NamedGraphs: NamedDiGraph

julia> g = NamedDiGraph(["a", "b"]);

julia> add_edge!(g, "a" => "b")
true

julia> has_edge(g, "a", "b")
true

julia> has_edge(g, "b", "a")
false
```
"""
NamedDiGraph

# Generic constructor for the named graph type corresponding to an encoded graph.
@traitfn function namedgraph(simple_graph::AbstractSimpleGraph::IsDirected, vertices)
    return NamedDiGraph(simple_graph, vertices)
end
@traitfn function namedgraph(simple_graph::AbstractSimpleGraph::(!IsDirected), vertices)
    return NamedGraph(simple_graph, vertices)
end

function rename_vertices(f::Function, g::AbstractSimpleGraph)
    return error(
        "Can't rename the vertices of a graph of type `$(typeof(g)) <: AbstractSimpleGraph`, try converting to a named graph."
    )
end

GraphsExtensions.directed_graph_type(::Type{<:NamedGraph{V}}) where {V} = NamedDiGraph{V}
GraphsExtensions.directed_graph_type(::Type{<:NamedDiGraph{V}}) where {V} = NamedDiGraph{V}
GraphsExtensions.undirected_graph_type(::Type{<:NamedGraph{V}}) where {V} = NamedGraph{V}
GraphsExtensions.undirected_graph_type(::Type{<:NamedDiGraph{V}}) where {V} = NamedGraph{V}

function edge_subgraph_namedgraph(graph::NamedDiGraph, edgelist)
    vs = unique(vcat(src.(edgelist), dst.(edgelist)))
    g = subgraph(graph, vs)
    rem_edges!(g, setdiff(edges(g), edgelist))
    return g
end
