using Graphs: AbstractGraph, Graphs, nv
using ..NamedGraphs: AbstractNamedGraph
using ..NamedGraphs.GraphsExtensions: GraphsExtensions, rem_vertices!

struct SuperVertex{V}
    vertex::V
end

Base.parent(sv::SuperVertex) = getfield(sv, :vertex)

supervertex(g::AbstractGraph, vertex) = SuperVertex(find_quotient_vertex(g, vertex))

"""
    supervertices(g::AbstractGraph, vs = vertices(pg))

Return all unique super vertices corresponding to the set vertices `vs` of the graph `pg`.
"""
supervertices(g::AbstractGraph) = SuperVertex.(quotient_vertices(g))
supervertices(g::AbstractGraph, vs) = unique(map(v -> supervertex(g,v), vs))

"""
    vertices(g::AbstractGraph, supervertex::SuperVertex)
    vertices(g::AbstractGraph, supervertices::Vector{SuperVertex})

Return the set of vertices in the graph `g` that correspond to the super vertex
`supervertex` or set of super vertices `supervertex`.
"""
function Graphs.vertices(g::AbstractGraph, supervertex::SuperVertex)
    return partitioned_vertices(g)[parent(supervertex)]
end
function Graphs.vertices(g::AbstractGraph, supervertices::Vector{<:SuperVertex})
    return unique(mapreduce(sv -> vertices(g, sv), vcat, supervertices))
end

# Avoid method ambiguity
Graphs.has_vertex(g::AbstractGraph, sv::SuperVertex) = has_super_vertex(g, sv)
Graphs.has_vertex(g::AbstractNamedGraph, sv::SuperVertex) = has_super_vertex(g, sv)

function has_super_vertex(g::AbstractGraph, supervertex::SuperVertex)
    return parent(supervertex) in quotient_vertices(g)
end

Graphs.nv(g::AbstractGraph, sv::SuperVertex) = length(vertices(g, sv))

function rem_super_vertex!(g::AbstractGraph, sv::SuperVertex)
    vertices_to_remove = vertices(g, sv)
    rem_vertices!(g, vertices_to_remove)
    return g
end

Graphs.rem_vertex!(g::AbstractGraph, sv::SuperVertex) = rem_super_vertex!(g, sv)
Graphs.rem_vertex!(g::AbstractNamedGraph, sv::SuperVertex) = rem_super_vertex!(g, sv)

function Graphs.induced_subgraph(
        g::AbstractGraph, supervertices::Union{SuperVertex, Vector{<:SuperVertex}}
    )
    return induced_subgraph(g, vertices(pg, supervertices))
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
