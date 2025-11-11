using Graphs: AbstractGraph, Graphs, nv
using ..NamedGraphs: AbstractNamedGraph
using ..NamedGraphs.GraphsExtensions: GraphsExtensions, rem_vertices!

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
    return partitioned_vertices(g)[parent(supervertex)]
end
function Graphs.vertices(g::AbstractGraph, supervertices::Vector{<:SuperVertex})
    return unique(mapreduce(sv -> vertices(g, sv), vcat, supervertices))
end

function has_supervertex(g::AbstractGraph, supervertex::SuperVertex)
    qg = quotient_graph_type(g)(quotient_vertices(g))
    return has_vertex(qg, parent(supervertex))
end

Graphs.nv(g::AbstractGraph, sv::SuperVertex) = length(vertices(g, sv))

function Graphs.induced_subgraph(
        g::AbstractGraph, supervertices::Union{SuperVertex, Vector{<:SuperVertex}}
    )
    return induced_subgraph(g, vertices(g, supervertices))
end
function Graphs.induced_subgraph(
        g::AbstractNamedGraph, svs::Union{SuperVertex, Vector{<:SuperVertex}}
    )
    gsvs = supervertices(g)
    if length(setdiff(gsvs, [svs;])) == length(gsvs)
        throw(ArgumentError("One or more supervertices not found in graph"))
    end
    return induced_subgraph(g, vertices(g, svs))
end


function GraphsExtensions.rem_vertices!(g::AbstractGraph, sv::SuperVertex)
    return rem_vertices!(g, vertices(g, sv))
end
rem_supervertex!(pg::AbstractGraph, sv::SuperVertex) = rem_vertices!(pg, sv)
