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
- `vertices(g::Named[Di]Graph)` outputs a
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
- The `Keys`, `SimilarType`, `GraphGenerators`, and `NamedGraphGenerators`
  submodules are removed. The named graph generators (`named_grid`,
  `named_path_graph`, and so on) and `similar_type` are accessible directly
  from `NamedGraphs`, the simple graph generators `comb_tree` and
  `binary_arborescence` move to `NamedGraphs.GraphsExtensions`, and the
  unused `Key` type is deleted
  ([#183](https://github.com/ITensor/NamedGraphs.jl/pull/183)).
- The wrappers around Graphs.jl functions now mirror the upstream positional
  signatures instead of taking `args...` or untyped arguments, so some
  argument types that were previously accepted no longer are
  ([#186](https://github.com/ITensor/NamedGraphs.jl/pull/186)). Three
  behaviours change with it. `eccentricity(graph, x)` always means the
  eccentricity of the single vertex `x`, so a bare distance matrix is a vertex
  rather than the every-vertex form, which is `eccentricities`. A `Vector{Bool}`
  passed to `induced_subgraph` is a list of vertex names rather than a mask over
  `1:nv(graph)`, since named graphs promise no correspondence between a
  vertex's position and its name. And an induced subgraph now throws for
  vertices the graph does not have, where it previously returned a graph built
  on them. `rename_vertices(edge, name_map)` is also gone, since it took its
  arguments in the opposite order from the rest of the interface: write
  `rename_vertices(v -> name_map[v], edge)`
  ([#184](https://github.com/ITensor/NamedGraphs.jl/pull/184)).
- `rename_vertices`, `disjoint_union`, and `⊔` move from
  `NamedGraphs.GraphsExtensions` to `NamedGraphs`, since they only work for
  graphs whose vertices are names, while `GraphsExtensions` holds extensions
  valid for any `Graphs.AbstractGraph`
  ([#187](https://github.com/ITensor/NamedGraphs.jl/pull/187)).
- Everything NamedGraphs documents is now exported, where previously only the
  four graph and edge types were, so `using NamedGraphs` brings considerably
  more into scope and can collide with another package's exports. Loading
  NamedGraphs and SimpleGraphs together, for one, now gives two
  `disjoint_union`. `NamedGraphs.GraphsExtensions` and
  `NamedGraphs.PartitionedGraphs` are marked `public` on Julia 1.11 and newer
  ([#188](https://github.com/ITensor/NamedGraphs.jl/pull/188)).
- The internal helpers behind the Graphs.jl wrappers are renamed from
  `namedgraph_f` to `f_namedgraph`, matching the suffix convention already used
  by `similar_namedgraph` and others. `AbstractNamedGraph` subtypes should now
  override these hooks rather than the Graphs.jl functions themselves, which
  means a subtype no longer needs its own `::Integer` disambiguator
  ([#187](https://github.com/ITensor/NamedGraphs.jl/pull/187)).

### Non-breaking changes

- Basic operations on a graph whose vertices happen to be integers work again.
  `common_neighbors(g, 1, 3)`, `has_path(g, 1, 3)`, `eccentricity(g, 1)`,
  `dijkstra_shortest_paths(g, 1)` and others were ambiguous with the Graphs.jl
  methods and raised a `MethodError`
  ([#186](https://github.com/ITensor/NamedGraphs.jl/pull/186),
  [#187](https://github.com/ITensor/NamedGraphs.jl/pull/187)).
  Indexing a `QuotientView` by a collection of vertices or edges was broken the
  same way and also works now.
- `Combinatorics`, `Random`, `Suppressor`, `SimpleGraphConverter`, and
  `PackageExtensionCompat` are no longer dependencies, so installing
  NamedGraphs no longer pulls in `Optim` or `LightXML`
  ([#185](https://github.com/ITensor/NamedGraphs.jl/pull/185),
  [#188](https://github.com/ITensor/NamedGraphs.jl/pull/188)).
- The docs are reorganized into user and developer interface pages, the graph
  types and generators are documented, and the README has an introduction and
  examples ([#183](https://github.com/ITensor/NamedGraphs.jl/pull/183)).
- `bfs_parents(g, v)` and `dfs_parents(g, v)` map vertices unreachable from
  `v` to themselves, like `dijkstra_shortest_paths` does. Previously they
  errored on graphs with unreachable vertices
  ([#179](https://github.com/ITensor/NamedGraphs.jl/pull/179)).
