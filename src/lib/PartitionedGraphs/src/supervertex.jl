using Graphs: AbstractGraph, Graphs, nv, induced_subgraph
using ..NamedGraphs: NamedGraphs, AbstractNamedGraph
using ..NamedGraphs.GraphsExtensions: GraphsExtensions, rem_vertices!, subgraph

struct SuperVertex{V}
    vertex::V
end

Base.parent(sv::SuperVertex) = getfield(sv, :vertex)

supervertex(g::AbstractGraph, vertex) = SuperVertex(quotient_vertex(g, vertex))

"""
    supervertices(g::AbstractGraph, vs = vertices(pg))

Return all unique super vertices corresponding to the set vertices `vs` of the graph `pg`.
"""
supervertices(g::AbstractGraph) = SuperVertex.(quotient_vertices(g))
supervertices(g::AbstractGraph, vs) = unique(map(v -> supervertex(g, v), vs))

"""
    vertices(g::AbstractGraph, supervertex::SuperVertex)
    vertices(g::AbstractGraph, supervertices::Vector{SuperVertex})

Return the set of vertices in the graph `g` associated with the super vertex
`supervertex` or set of super vertices `supervertices`.
"""
function Graphs.vertices(g::AbstractGraph, supervertex::SuperVertex)
    qv = parent(supervertex)

    pvs = partitioned_vertices(g)
    haskey(pvs, qv) || throw(ArgumentError("Super vertex $supervertex not in graph"))

    return pvs[qv]
end
function Graphs.vertices(g::AbstractGraph, supervertices::Vector{<:SuperVertex})
    return unique(mapreduce(sv -> vertices(g, sv), vcat, supervertices))
end

function has_supervertex(g::AbstractGraph, supervertex::SuperVertex)
    qg = quotient_graph_type(g)(quotient_vertices(g))
    return has_vertex(qg, parent(supervertex))
end

Graphs.nv(g::AbstractGraph, sv::SuperVertex) = length(vertices(g, sv))

function GraphsExtensions.rem_vertices!(g::AbstractGraph, sv::SuperVertex)
    return rem_vertices!(g, vertices(g, sv))
end
rem_supervertex!(pg::AbstractGraph, sv::SuperVertex) = rem_vertices!(pg, sv)

function NamedGraphs.to_vertices(g::AbstractGraph, sv::Union{SV, Vector{SV}}) where {SV <: SuperVertex}
    return vertices(g, sv)
end
