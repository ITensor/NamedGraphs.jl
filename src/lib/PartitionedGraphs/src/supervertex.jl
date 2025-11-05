using Graphs: AbstractGraph, Graphs, nv
using ..NamedGraphs: AbstractNamedGraph
using ..NamedGraphs.GraphsExtensions: GraphsExtensions, rem_vertices!

struct SuperVertex{V}
    vertex::V
end

Base.parent(sv::SuperVertex) = getfield(sv, :vertex)

# Avoid method ambiguity
Graphs.has_vertex(g::AbstractGraph, sv::SuperVertex) = has_super_vertex(g, sv)
Graphs.has_vertex(g::AbstractNamedGraph, sv::SuperVertex) = has_super_vertex(g, sv)

function has_super_vertex(g::AbstractGraph, supervertex::SuperVertex)
    return parent(supervertex) in quotient_vertices(g)
end

Graphs.nv(g::AbstractGraph, sv::SuperVertex) = length(partitioned_vertices(g, sv))

function rem_super_vertex!(g::AbstractGraph, sv::SuperVertex)
    vertices_to_remove = partitioned_vertices(g, sv)
    rem_vertices!(g, vertices_to_remove)
    return g
end

Graphs.rem_vertex!(g::AbstractGraph, sv::SuperVertex) = rem_super_vertex!(g, sv)
