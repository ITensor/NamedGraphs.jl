# Developer Interface

```@meta
CurrentModule = NamedGraphs
CollapsedDocStrings = true
```

This page describes how to define a new [`AbstractNamedGraph`](@ref): subtype it
and overload the minimal interface below, the graph on integer vertex codes and
the translation between names and codes. Everything
else in the Graphs.jl interface has generic fallbacks in terms of these.
Graph types that do not store an integer graph get a generic
`EncodedGraphView` fallback for `encoded_graph` and only need `encode_vertex`
and `decode_vertex`.

Vertex codes are not stable across mutation: adding or removing vertices may
reassign the codes of other vertices.

These names are `public` rather than exported, so reach them with
`using NamedGraphs: encode_vertex` or by qualifying.

```@docs; canonical=false
encoded_graph
encode_vertex
decode_vertex
encode_edge
decode_edge
```
