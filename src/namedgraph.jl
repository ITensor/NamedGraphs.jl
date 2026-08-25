using .GraphsExtensions: GraphsExtensions, directed_graph_type, similar_graph,
    similar_simplegraph, undirected_graph_type, vertextype
using Dictionaries: Dictionary
using Graphs.SimpleGraphs: AbstractSimpleGraph, SimpleDiGraph, SimpleGraph
using Graphs: Graphs, AbstractGraph, add_edge!, add_vertex!, edgetype, has_edge,
    is_directed, outneighbors, rem_vertex!, vertices

struct GenericNamedGraph{V, G <: AbstractSimpleGraph{Int}} <: AbstractNamedGraph{V}
    encoded_graph::G
    code_to_vertex::Vector{V}
    vertex_to_code::Dictionary{V, Int}
    function GenericNamedGraph{V, G}(graph, vertices) where {V, G}
        encoded_graph = G(graph)
        code_to_vertex = collect(V, to_vertices(encoded_graph, vertices))
        @assert length(code_to_vertex) == nv(encoded_graph)
        # `copy` since the `Dictionary` takes ownership of the key vector, which
        # would otherwise alias the `code_to_vertex` field.
        vertex_to_code =
            Dictionary{V, Int}(copy(code_to_vertex), eachindex(code_to_vertex))
        return new{V, G}(encoded_graph, code_to_vertex, vertex_to_code)
    end
end

# AbstractNamedGraph required interface.
function encode_graph_type(graph_type::Type{<:GenericNamedGraph})
    return fieldtype(graph_type, :encoded_graph)
end
encode_graph(graph::GenericNamedGraph) = graph.encoded_graph
encode_vertex(graph::GenericNamedGraph, vertex) = graph.vertex_to_code[vertex]
decode_vertex(graph::GenericNamedGraph, code::Integer) = graph.code_to_vertex[code]
code_to_vertex(graph::GenericNamedGraph) = graph.code_to_vertex
vertex_to_code(graph::GenericNamedGraph) = graph.vertex_to_code

Graphs.vertices(graph::GenericNamedGraph) = keys(graph.vertex_to_code)

function Graphs.add_vertex!(graph::GenericNamedGraph, vertex)
    if vertex ∈ vertices(graph)
        return false
    end
    add_vertex!(encode_graph(graph))
    push!(graph.code_to_vertex, vertex)
    insert!(graph.vertex_to_code, vertex, nv(encode_graph(graph)))
    return true
end

function Graphs.rem_vertex!(graph::GenericNamedGraph, vertex)
    if vertex ∉ vertices(graph)
        return false
    end
    code = encode_vertex(graph, vertex)
    # `rem_vertex!` on an `AbstractSimpleGraph` moves the last vertex into the
    # removed slot, so mirror that reassignment in the vertex-code maps.
    rem_vertex!(encode_graph(graph), code)
    last_vertex = pop!(graph.code_to_vertex)
    delete!(graph.vertex_to_code, vertex)
    if vertex ≠ last_vertex
        graph.code_to_vertex[code] = last_vertex
        graph.vertex_to_code[last_vertex] = code
    end
    return graph
end

function GraphsExtensions.rename_vertices(f::Function, graph::GenericNamedGraph)
    return GenericNamedGraph(copy(encode_graph(graph)), map(f, graph.code_to_vertex))
end

function GraphsExtensions.rename_vertices(f::Function, g::AbstractSimpleGraph)
    return error(
        "Can't rename the vertices of a graph of type `$(typeof(g)) <: AbstractSimpleGraph`, try converting to a named graph."
    )
end

function GraphsExtensions.convert_vertextype(vertextype::Type, graph::GenericNamedGraph)
    return GenericNamedGraph(
        encode_graph(graph), convert(Vector{vertextype}, graph.code_to_vertex)
    )
end

#
# Constructors from `AbstractSimpleGraph`
#

to_vertices(graph, vertices) = _to_vertices(graph, vertices)
_to_vertices(::AbstractSimpleGraph, vertices) = to_vertices(vertices)
_to_vertices(::AbstractGraph, vertices) = vertices

to_vertices(vertices) = vertices
to_vertices(vertices::AbstractArray) = vec(vertices)
to_vertices(vertices::Integer) = Base.OneTo(vertices)

function GenericNamedGraph{V}(encode_graph::AbstractSimpleGraph, vertices) where {V}
    return GenericNamedGraph{V, typeof(encode_graph)}(encode_graph, vertices)
end

function GenericNamedGraph{<:Any, G}(
        encode_graph::AbstractSimpleGraph, vertices
    ) where {G <: AbstractSimpleGraph{Int}}
    return GenericNamedGraph{eltype(vertices), G}(encode_graph, vertices)
end

function GenericNamedGraph{<:Any, G}(
        encode_graph::AbstractSimpleGraph
    ) where {G <: AbstractSimpleGraph{Int}}
    return GenericNamedGraph{<:Any, G}(encode_graph, vertices(encode_graph))
end

function GenericNamedGraph(encode_graph::AbstractSimpleGraph, vertices)
    return GenericNamedGraph{eltype(vertices)}(encode_graph, vertices)
end

function GenericNamedGraph(encode_graph::AbstractSimpleGraph)
    return GenericNamedGraph(encode_graph, vertices(encode_graph))
end

#
# Tautological constructors
#

function GenericNamedGraph{V, G}(
        graph::GenericNamedGraph{V, G}
    ) where {V, G <: AbstractSimpleGraph{Int}}
    return copy(graph)
end

#
# Constructors from vertex names
#

function GenericNamedGraph{V, G}(vertices) where {V, G <: AbstractSimpleGraph{Int}}
    return GenericNamedGraph{V, G}(G(length(to_vertices(vertices))), vertices)
end

function GenericNamedGraph{V}(vertices) where {V}
    return GenericNamedGraph{V, SimpleGraph{Int}}(vertices)
end

function GenericNamedGraph{<:Any, G}(vertices) where {G <: AbstractSimpleGraph{Int}}
    return GenericNamedGraph{eltype(vertices), G}(vertices)
end

function GenericNamedGraph(vertices)
    return GenericNamedGraph{eltype(vertices)}(vertices)
end

#
# Empty constructors
#

function GenericNamedGraph{V, G}() where {V, G <: AbstractSimpleGraph{Int}}
    return GenericNamedGraph{V, G}(V[])
end

GenericNamedGraph{V}() where {V} = GenericNamedGraph{V}(V[])

function GenericNamedGraph{<:Any, G}() where {G <: AbstractSimpleGraph{Int}}
    return GenericNamedGraph{<:Any, G}(Any[])
end

GenericNamedGraph() = GenericNamedGraph(Any[])

function GenericNamedGraph(graph::GenericNamedGraph)
    return GenericNamedGraph{vertextype(graph), encode_graph_type(graph)}(graph)
end
function GenericNamedGraph{V}(graph::GenericNamedGraph) where {V}
    return GenericNamedGraph{V, encode_graph_type(graph)}(graph)
end
function GenericNamedGraph{<:Any, G}(
        graph::GenericNamedGraph
    ) where {G <: AbstractSimpleGraph{Int}}
    return GenericNamedGraph{vertextype(graph), G}(graph)
end
function GenericNamedGraph{V, G}(
        graph::GenericNamedGraph
    ) where {V, G <: AbstractSimpleGraph{Int}}
    return GenericNamedGraph{V, G}(copy(encode_graph(graph)), copy(graph.code_to_vertex))
end

function Base.convert(graph_type::Type{<:GenericNamedGraph}, graph::GenericNamedGraph)
    return graph_type(graph)
end

Base.copy(graph::GenericNamedGraph) = similar_graph(graph)

Graphs.edgetype(graph_type::Type{<:GenericNamedGraph}) = NamedEdge{vertextype(graph_type)}

function GraphsExtensions.directed_graph_type(graph_type::Type{<:GenericNamedGraph})
    return GenericNamedGraph{
        vertextype(graph_type), directed_graph_type(encode_graph_type(graph_type)),
    }
end
function GraphsExtensions.undirected_graph_type(graph_type::Type{<:GenericNamedGraph})
    return GenericNamedGraph{
        vertextype(graph_type), undirected_graph_type(encode_graph_type(graph_type)),
    }
end

function Graphs.is_directed(graph_type::Type{<:GenericNamedGraph})
    return is_directed(encode_graph_type(graph_type))
end

function Base.reverse!(graph::GenericNamedGraph)
    reverse!(encode_graph(graph))
    return graph
end
function Base.reverse(graph::GenericNamedGraph)
    return GenericNamedGraph(reverse(encode_graph(graph)), copy(graph.code_to_vertex))
end

#
# Type aliases
#

const NamedGraph{V} = GenericNamedGraph{V, SimpleGraph{Int}}
const NamedDiGraph{V} = GenericNamedGraph{V, SimpleDiGraph{Int}}

function GraphsExtensions.similar_graph(graph::GenericNamedGraph, nv::Int)
    return similar_simplegraph(graph, nv)
end
function GraphsExtensions.similar_graph(
        ::GenericNamedGraph{<:Any, G},
        vertices
    ) where {G}
    V = eltype(vertices)
    graph = similar_graph(GenericNamedGraph{V, G}, vertices)
    # HACK: Unsure why this annotation is needed, but some type inference fails without it.
    return graph::GenericNamedGraph{V, G}
end

function GraphsExtensions.similar_graph(T::Type{<:GenericNamedGraph}, vertices)
    return T(vertices)
end

function edge_subgraph_namedgraph(graph::NamedDiGraph, edgelist)
    vs = unique(vcat(src.(edgelist), dst.(edgelist)))
    g = subgraph(graph, vs)
    g = rem_edges!(g, setdiff(edges(g), edgelist))
    return g
end
