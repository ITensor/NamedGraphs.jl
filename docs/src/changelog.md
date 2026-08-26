# Changelog

## [0.14.0](https://github.com/ITensor/NamedGraphs.jl/compare/v0.13.0...main) - Unreleased

Reworks how named vertices and edges are translated to the integer vertices
and edges used internally.

### Breaking changes

- The "position graph" terminology is replaced with encode and decode
  terminology. The overloads for implementing a new `AbstractNamedGraph` are
  `encoded_graph(g)` (replaces `position_graph`, with a generic
  `EncodedGraphView` fallback so a graph type does not need to store an
  integer graph), `encode_vertex(g, v)` (replaces `vertex_positions`), and
  `decode_vertex(g, c)` (replaces `ordered_vertices`). Codes are not stable
  across mutation
  ([#178](https://github.com/ITensor/NamedGraphs.jl/pull/178)).
- The `OrdinalIndexing` submodule is removed, so `vertices(g)[4th]` becomes
  `decode_vertex(g, 4)`
  ([#178](https://github.com/ITensor/NamedGraphs.jl/pull/178)).
- `vertices(g::NamedGraph)` (and `NamedDiGraph`) outputs a
  `Dictionaries.Indices` instead of the internal `OrderedIndices` type, which
  is removed along with the `OrderedDictionaries` submodule. Other
  `AbstractNamedGraph` types can output other `AbstractIndices` set views.
  Vertices iterate in insertion order, which is stable under removals and
  therefore no longer matches the integer codes after removals, so code that
  aligns `vertices(g)` with results computed on the integer graph should
  translate through `decode_vertex`
  ([#178](https://github.com/ITensor/NamedGraphs.jl/pull/178)).
- `edges(g)` outputs a lazy iterator instead of a `Vector`, like
  `edges(::SimpleGraph)` in Graphs.jl. Membership (`in`) matches `has_edge`,
  and `==` between two edge iterators compares the edge sets. Code that
  indexed into the output should `collect` it first
  ([#178](https://github.com/ITensor/NamedGraphs.jl/pull/178)).
- `GenericNamedGraph{V, G}` is removed (it was not exported, so this only
  affects code that imported it explicitly). `NamedGraph{V}` and
  `NamedDiGraph{V}` are now separately defined concrete types, hardcoded to
  `SimpleGraph{Int}` and `SimpleDiGraph{Int}` underlying storage
  ([#179](https://github.com/ITensor/NamedGraphs.jl/pull/179)).
- `rem_vertex!`, `add_edge!`, and `rem_edge!` return `true` or `false`
  following Graphs.jl, matching `add_vertex!`. Previously they returned the
  graph on success, and `add_edge!`/`rem_edge!` threw for edges with vertices
  not in the graph, which now returns `false`
  ([#179](https://github.com/ITensor/NamedGraphs.jl/pull/179)).

### Non-breaking changes

- `bfs_parents(g, v)` and `dfs_parents(g, v)` map vertices unreachable from
  `v` to themselves, like `dijkstra_shortest_paths` does. Previously they
  errored on graphs with unreachable vertices
  ([#179](https://github.com/ITensor/NamedGraphs.jl/pull/179)).
