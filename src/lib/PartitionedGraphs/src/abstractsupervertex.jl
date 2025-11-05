using Graphs: Graphs, AbstractGraph, nv, has_vertex, rem_vertex!
using ..NamedGraphs: AbstractNamedGraph
using ..NamedGraphs.GraphsExtensions: GraphsExtensions, not_implemented, rem_vertices!, rem_vertex

abstract type AbstractSuperVertex{V} <: Any where {V} end

#Parent, wrap, unwrap, vertex?
Base.parent(::AbstractSuperVertex) = not_implemented()

# Avoid method ambiguity
Graphs.has_vertex(g::AbstractGraph, sv::AbstractSuperVertex) = has_super_vertex(g, sv)
Graphs.has_vertex(g::AbstractNamedGraph, sv::AbstractSuperVertex) = has_super_vertex(g, sv)

function has_super_vertex(g::AbstractGraph, supervertex::AbstractSuperVertex)
    return parent(supervertex) in quotient_vertices(g)
end

Graphs.nv(g::AbstractGraph, sv::AbstractSuperVertex) = length(partitioned_vertices(g, sv))

function rem_super_vertex!(g::AbstractGraph, sv::AbstractSuperVertex)
    vertices_to_remove = partitioned_vertices(g, sv)
    rem_vertices!(g, vertices_to_remove)
    return g
end

Graphs.rem_vertex!(g::AbstractGraph, sv::AbstractSuperVertex) = rem_super_vertex!(g, sv)

GraphsExtensions.rem_vertex(g, sv) = rem_vertex!(copy(g), sv)
