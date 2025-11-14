using Graphs: AbstractGraph, Graphs, nv, induced_subgraph
using ..NamedGraphs: NamedGraphs, AbstractNamedGraph
using ..NamedGraphs.GraphsExtensions: GraphsExtensions, rem_vertices!, subgraph
using ..NamedGraphs.OrderedDictionaries: OrderedIndices


struct QuotientVertex{V}
    vertex::V
end

Base.parent(sv::QuotientVertex) = getfield(sv, :vertex)

# Overload this for fast inverse mapping for vertices and edges
function quotientvertex(g, vertex)
    pvs = partitioned_vertices(g)
    rv = findfirst(pv -> vertex ∈ pv, pvs)
    if isnothing(rv)
        error("Vertex $vertex not found in any partition.")
    end
    return QuotientVertex(rv)
end

"""
    quotientvertices(g::AbstractGraph, vs = vertices(pg))

Return all unique quotient vertices corresponding to the set vertices `vs` of the graph `pg`.
"""
quotientvertices(g) = QuotientVertex.(keys(partitioned_vertices(g)))
quotientvertices(g::AbstractGraph, vs) = unique(map(v -> quotientvertex(g, v), vs))

"""
    vertices(g::AbstractGraph, quotientvertex::QuotientVertex)
    vertices(g::AbstractGraph, quotientvertices::Vector{QuotientVertex})

Return the set of vertices in the graph `g` associated with the quotient vertex
`quotientvertex` or set of quotient vertices `quotientvertices`.
"""
function Graphs.vertices(g::AbstractGraph, quotientvertex::QuotientVertex)
    qv = parent(quotientvertex)

    pvs = partitioned_vertices(g)
    haskey(pvs, qv) || throw(ArgumentError("Super vertex $quotientvertex not in graph"))

    return pvs[qv]
end
function Graphs.vertices(g::AbstractGraph, quotientvertices::Vector{<:QuotientVertex})
    return unique(mapreduce(sv -> vertices(g, sv), vcat, quotientvertices))
end

function has_quotientvertex(g::AbstractGraph, quotientvertex::QuotientVertex)
    qg = quotient_graph_type(g)(parent.(quotientvertices(g)))
    return has_vertex(qg, parent(quotientvertex))
end

Graphs.nv(g::AbstractGraph, sv::QuotientVertex) = length(vertices(g, sv))

function GraphsExtensions.rem_vertices!(g::AbstractGraph, sv::QuotientVertex)
    return rem_vertices!(g, vertices(g, sv))
end
rem_quotientvertex!(pg::AbstractGraph, sv::QuotientVertex) = rem_vertices!(pg, sv)

function NamedGraphs.to_vertices(g::AbstractGraph, sv::Union{SV, Vector{SV}}) where {SV <: QuotientVertex}
    return vertices(g, sv)
end
