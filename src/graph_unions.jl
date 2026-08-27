using Dictionaries: Dictionary, dictionary
using Graphs: AbstractGraph

# Renaming vertices and taking disjoint unions only make sense for graphs whose
# vertices are names, so they live here rather than in `GraphsExtensions`, which
# holds extensions that apply to any `Graphs.AbstractGraph`.

"""
    rename_vertices(f, graph::AbstractGraph)

A graph with the same edges as `graph` but with each vertex `v` renamed to
`f(v)`. Only defined for graphs with named vertices: renaming the vertices of a
`Graphs.AbstractSimpleGraph` is an error, since its vertices are the fixed
integers `1:nv(graph)`.

# Examples

```jldoctest
julia> using Graphs: edges, path_graph, vertices

julia> using NamedGraphs: NamedEdge, NamedGraph, rename_vertices

julia> g = NamedGraph(path_graph(3), ["a", "b", "c"]);

julia> h = rename_vertices(uppercase, g);

julia> collect(vertices(h))
3-element Vector{String}:
 "A"
 "B"
 "C"

julia> collect(edges(h))
2-element Vector{NamedEdge{String}}:
 "A" => "B"
 "B" => "C"
```
"""
rename_vertices(f, g::AbstractGraph) = not_implemented()

"""
    disjoint_union(graphs...)
    disjoint_union(graphs::Vector)
    disjoint_union(pairs::Pair...)
    graph1 ⊔ graph2

The [disjoint union](https://en.wikipedia.org/wiki/Disjoint_union) of the
graphs: their union after renaming each vertex `v` of the `i`th graph to
`(v, i)`, so that vertices shared between the inputs stay distinct in the
output. `⊔` is an alias. Passing pairs `i => graph` names the graphs explicitly
instead of by position.

Only defined for graphs with named vertices, since it renames them (see
[`rename_vertices`](@ref)).

# Examples

```jldoctest
julia> using Graphs: edges, path_graph, vertices

julia> using NamedGraphs: NamedEdge, NamedGraph, ⊔

julia> g = NamedGraph(path_graph(2), ["a", "b"]);

julia> h = g ⊔ g;

julia> collect(vertices(h))
4-element Vector{Tuple{String, Int64}}:
 ("a", 1)
 ("b", 1)
 ("a", 2)
 ("b", 2)

julia> collect(edges(h))
2-element Vector{NamedEdge{Tuple{String, Int64}}}:
 ("a", 1) => ("b", 1)
 ("a", 2) => ("b", 2)
```
"""
function disjoint_union(graphs::Dictionary{<:Any, <:AbstractGraph})
    return reduce(union, (rename_vertices(v -> (v, i), graphs[i]) for i in keys(graphs)))
end

function disjoint_union(graphs::Vector{<:AbstractGraph})
    return disjoint_union(Dictionary(graphs))
end

disjoint_union(graph::AbstractGraph) = graph

function disjoint_union(graph1::AbstractGraph, graphs_tail::AbstractGraph...)
    return disjoint_union(Dictionary([graph1, graphs_tail...]))
end

function disjoint_union(pairs::Pair...)
    return disjoint_union([pairs...])
end

function disjoint_union(iter::Vector{<:Pair})
    return disjoint_union(dictionary(iter))
end

"""
    graph1 ⊔ graph2
    ⊔(graphs...)

Alias for [`disjoint_union`](@ref).
"""
function ⊔(graphs...; kwargs...)
    return disjoint_union(graphs...; kwargs...)
end
