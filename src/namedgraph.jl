using .GraphsExtensions: GraphsExtensions, similar_graph, similar_simplegraph, vertextype
using Dictionaries: Dictionary
using Graphs.SimpleGraphs: AbstractSimpleGraph, SimpleDiGraph, SimpleGraph
using Graphs: Graphs, AbstractGraph, add_edge!, add_vertex!, blockdiag, edgetype, has_edge,
    is_directed, outneighbors, rem_vertex!, vertices

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
                encoded_graph = $GT{Int}(graph)
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
        encoded_graph(graph::$T) = graph.encoded_graph
        encode_vertex(graph::$T, vertex) = graph.encoded_vertices[vertex]
        decode_vertex(graph::$T, code::Integer) = graph.decoded_vertices[code]

        Graphs.vertices(graph::$T) = keys(graph.encoded_vertices)

        function Graphs.add_vertex!(graph::$T, vertex)
            if vertex ∈ vertices(graph)
                return false
            end
            add_vertex!(encoded_graph(graph))
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

        function GraphsExtensions.rename_vertices(f::Function, graph::$T)
            return $T(copy(encoded_graph(graph)), map(f, graph.decoded_vertices))
        end

        function GraphsExtensions.convert_vertextype(vertextype::Type, graph::$T)
            return $T(
                encoded_graph(graph), convert(Vector{vertextype}, graph.decoded_vertices)
            )
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
            return $T{V}($GT{Int}(length(to_vertices(vertices))), vertices)
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

        Base.copy(graph::$T) = similar_graph(graph)

        Graphs.edgetype(graph_type::Type{<:$T}) = NamedEdge{vertextype(graph_type)}

        Graphs.is_directed(graph_type::Type{<:$T}) = is_directed($GT{Int})

        function Base.reverse!(graph::$T)
            reverse!(encoded_graph(graph))
            return graph
        end
        function Base.reverse(graph::$T)
            return $T(reverse(encoded_graph(graph)), copy(graph.decoded_vertices))
        end

        function GraphsExtensions.similar_graph(graph::$T, nv::Int)
            return similar_simplegraph(graph, nv)
        end
        function GraphsExtensions.similar_graph(::$T, vertices)
            return $T{eltype(vertices)}(vertices)
        end
        GraphsExtensions.similar_graph(graph_type::Type{<:$T}, vertices) =
            graph_type(vertices)

        function Graphs.blockdiag(graph1::$T, graph2::$T)
            new_encoded_graph = blockdiag(encoded_graph(graph1), encoded_graph(graph2))
            new_vertices = vcat(graph1.decoded_vertices, graph2.decoded_vertices)
            @assert allunique(new_vertices)
            return $T(new_encoded_graph, new_vertices)
        end
    end
end

function GraphsExtensions.rename_vertices(f::Function, g::AbstractSimpleGraph)
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
    g = rem_edges!(g, setdiff(edges(g), edgelist))
    return g
end
