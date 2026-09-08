# Developer Interface

```@meta
CurrentModule = NamedGraphs
CollapsedDocStrings = true
```

## Defining a new `AbstractNamedGraph`

Subtype [`AbstractNamedGraph`](@ref) and overload the minimal interface below,
the graph on integer vertex codes and the translation between names and codes.
Everything else in the Graphs.jl interface has generic fallbacks in terms of
these.

A graph type that does not store an integer graph can leave `encoded_graph` to
its generic `EncodedGraphView` fallback and define only `encoded_vertex` and
`decoded_vertex` for the translation. The view answers `nv`, `ne`, `has_vertex`,
`has_edge`, `edges`, and the neighbor queries by asking the named graph itself,
so such a type must also define those directly, or every one of them recurses.
`NamedGridGraph` is the model: it computes its topology from the grid size and
uses the view only to present it on integer codes.

Rather than overloading a Graphs.jl function on your subtype, overload the hook
it forwards to, named `f_namedgraph` for a Graphs.jl function `f`
(`neighbors_namedgraph`, `dijkstra_shortest_paths_namedgraph`, and so on). The
Graphs.jl functions are defined once on `AbstractNamedGraph`, in both the untyped
and `::Integer` vertex forms, and forward to the hook. Overloading the hook keeps
a subtype's methods unambiguous with Graphs.jl's own `::Integer` methods on a
graph whose vertex names are integers, with no disambiguator of its own.

Vertex codes are not stable across mutation: adding or removing vertices may
reassign the codes of other vertices.

These names are `public` rather than exported, so reach them with
`using NamedGraphs: encoded_vertex` or by qualifying.

```@docs; canonical=false
encoded_graph
encoded_vertex
decoded_vertex
encoded_edge
decoded_edge
```

## Graphs.jl interface extensions

NamedGraphs also defines generic extensions of the Graphs.jl interface. Many of
them are written against `Graphs.AbstractGraph` rather than against named graphs,
so they work for any graph type, including `Graphs.SimpleGraph`. The rest need
vertices that carry names and are only defined for [`AbstractNamedGraph`](@ref).
