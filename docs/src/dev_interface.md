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

A graph type that does not store an integer graph can return
[`EncodedGraphView(g)`](@ref EncodedGraphView) from `encoded_graph`. The view
answers `nv`, `ne`, `has_vertex`, `has_edge`, `edges`, and the neighbor queries
by asking the named graph itself, so such a type defines those directly.

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
EncodedGraphView
```

## Graphs.jl interface extensions

NamedGraphs also defines generic extensions of the Graphs.jl interface. Many of
them are written against `Graphs.AbstractGraph` rather than against named graphs,
so they work for any graph type, including `Graphs.SimpleGraph`. The rest need
vertices that carry names and are only defined for [`AbstractNamedGraph`](@ref).
