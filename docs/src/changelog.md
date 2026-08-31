# Changelog

## [0.14.0](https://github.com/ITensor/NamedGraphs.jl/compare/v0.13.0...main) - Unreleased

Reworks how named vertices and edges are translated to the integer vertices
and edges used internally.

### Breaking changes

- The `NamedGraphGenerators`, `GraphsExtensions`, `GraphGenerators`, and
  `SimilarType` submodules are removed and their contents moved into
  `NamedGraphs`, so `using NamedGraphs.GraphsExtensions: boundary_edges` becomes
  `using NamedGraphs: boundary_edges`,
  `using NamedGraphs.NamedGraphGenerators: named_grid` becomes
  `using NamedGraphs: named_grid`, and so on
  ([#183](https://github.com/ITensor/NamedGraphs.jl/pull/183),
  [#187](https://github.com/ITensor/NamedGraphs.jl/pull/187),
  [#189](https://github.com/ITensor/NamedGraphs.jl/pull/189),
  [#190](https://github.com/ITensor/NamedGraphs.jl/pull/190)).
- `edges(g)` outputs a lazy iterator instead of a `Vector`, like
  `edges(::SimpleGraph)` in Graphs.jl. Membership (`in`) matches `has_edge`, and
  `==` between two edge iterators compares the edge sets. Code that indexed,
  `filter`ed, or `findfirst`ed the result should `collect` it first, and `vcat`
  takes the iterator as a single element rather than a collection, so it
  silently returns a nested `Vector{Any}` where it previously combined the edges.
  Iteration, `length`, `first`, `issetequal`, `union`, `setdiff`, broadcasting,
  and building a `Dictionary` or `Indices` all work directly. The output is a
  live view of the graph rather than a snapshot, so holding on to it across a
  mutation of the graph now sees the mutation
  ([#178](https://github.com/ITensor/NamedGraphs.jl/pull/178)).
- `vertices(g::Named[Di]Graph)` outputs a `Dictionaries.Indices` instead of the
  internal `OrderedIndices` type, and the `OrderedDictionaries` and
  `OrdinalIndexing` submodules are removed along with their contents. Other
  `AbstractNamedGraph` types can output other `AbstractIndices` set views.
  Indexing is by vertex name, not position, and `vertices(g)[4th]` becomes
  `decoded_vertex(g, 4)`
  ([#178](https://github.com/ITensor/NamedGraphs.jl/pull/178)).
- Vertices iterate in insertion order, which no longer matches the integer codes
  after a removal, where v0.13 kept the two in agreement. Nothing errors, so code
  that maps a result computed on the integer graph back through
  `collect(vertices(g))[code]` silently gets the wrong vertex. Translate with
  `decoded_vertex(g, code)` instead
  ([#178](https://github.com/ITensor/NamedGraphs.jl/pull/178)).
- The "position graph" terminology is replaced with encode and decode
  terminology. The overloads for implementing a new `AbstractNamedGraph` are
  `encoded_graph(g)` (replaces `position_graph`, with a generic
  `EncodedGraphView` fallback so a graph type does not need to store an integer
  graph), `encoded_vertex(g, v)` (replaces `vertex_positions`), and
  `decoded_vertex(g, c)` (replaces `ordered_vertices`). Codes are not stable
  across mutation. The last two translate a single vertex where the functions
  they replace returned a whole mapping, so a type that forwarded all three in a
  loop over function names has to write them out separately
  ([#178](https://github.com/ITensor/NamedGraphs.jl/pull/178)).
- `rem_vertex!`, `add_edge!`, and `rem_edge!` return `true` or `false` following
  Graphs.jl, matching `add_vertex!`. Previously they returned the graph, and
  `add_edge!`/`rem_edge!` threw for edges with vertices not in the graph, which
  now returns `false`. A type defining these needs a `has_vertex` guard so that
  removing an absent vertex returns `false` instead of throwing, and
  `Dictionaries.unset!` in place of `delete!`
  ([#179](https://github.com/ITensor/NamedGraphs.jl/pull/179)).
- The plural mutators `add_edges!`, `rem_edges!`, `add_vertices!`, and
  `rem_vertices!` return the number of successful additions or removals, where
  they previously returned the graph. `Bool` from the singular
  `Graphs.add_edge!` is the one-element case of the same count, and
  `Graphs.add_vertices!` already returned a count. `rem_quotientvertex!` and
  `rem_quotientedge!` likewise return how many underlying vertices or edges went,
  so `0` means the quotient vertex or edge was not there
  ([#188](https://github.com/ITensor/NamedGraphs.jl/pull/188)).
- `add_vertices!` and `rem_vertices!` are methods of the Graphs.jl functions of
  those names rather than separate functions of NamedGraphs' own, and are
  declared on `AbstractNamedGraph`. An integer second argument is a vertex name
  here, not upstream's count of vertices to append, since a named graph cannot
  invent names ([#188](https://github.com/ITensor/NamedGraphs.jl/pull/188)).
- Considerably more names are exported, where previously only the four graph and
  edge types were, so `using NamedGraphs` can collide with names another package
  exports ([#188](https://github.com/ITensor/NamedGraphs.jl/pull/188)).
- The `Keys` submodule and its `Key` type are removed with no replacement. Code
  that used `Key` needs its own equivalent
  ([#183](https://github.com/ITensor/NamedGraphs.jl/pull/183)).
- `all_edges` takes an `AbstractNamedGraph`, where it previously took any
  `Graphs.AbstractGraph`, and outputs a lazy iterator, so on a directed graph it
  no longer returns an allocated `Vector`
  ([#192](https://github.com/ITensor/NamedGraphs.jl/pull/192)).
- `GenericNamedGraph{V, G}` is removed (it was not exported, so this only
  affects code that imported it explicitly). `NamedGraph{V}` and
  `NamedDiGraph{V}` are now separately defined concrete types, hardcoded to
  `SimpleGraph{Int}` and `SimpleDiGraph{Int}` underlying storage
  ([#179](https://github.com/ITensor/NamedGraphs.jl/pull/179)).
- The wrappers around Graphs.jl functions mirror the upstream positional
  signatures instead of taking `args...` or untyped arguments, so some argument
  types that were previously accepted no longer are. In particular,
  `eccentricity(graph, x)` is always the eccentricity of the single vertex `x`,
  with `eccentricities` as the every-vertex form, and a `Vector{Bool}` passed to
  `induced_subgraph` is a list of vertex names rather than a mask over
  `1:nv(graph)`. `induced_subgraph` also throws for vertices the graph does not
  have, where it previously returned a graph built on them
  ([#186](https://github.com/ITensor/NamedGraphs.jl/pull/186)).
- `rename_vertices(edge, name_map)` is removed. Write
  `rename_vertices(v -> name_map[v], edge)`
  ([#184](https://github.com/ITensor/NamedGraphs.jl/pull/184)).
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
- `all_edges` is documented and exported
  ([#192](https://github.com/ITensor/NamedGraphs.jl/pull/192)).
- `Combinatorics`, `Random`, `Suppressor`, `SimpleGraphConverter`, and
  `PackageExtensionCompat` are no longer dependencies, so installing
  NamedGraphs no longer pulls in `Optim` or `LightXML`
  ([#185](https://github.com/ITensor/NamedGraphs.jl/pull/185),
  [#188](https://github.com/ITensor/NamedGraphs.jl/pull/188)).
- The docs are reorganized into user and developer interface pages, the graph
  types and generators are documented, and the README has an introduction and
  examples ([#183](https://github.com/ITensor/NamedGraphs.jl/pull/183)).
- `NamedGraphs.PartitionedGraphs` documents and exports its user-facing API, so
  `using NamedGraphs.PartitionedGraphs` brings the partitioned graph types and
  the quotient vertex and edge functions into scope where it previously brought
  nothing ([#188](https://github.com/ITensor/NamedGraphs.jl/pull/188)).
- `bfs_parents(g, v)` and `dfs_parents(g, v)` map vertices unreachable from
  `v` to themselves, like `dijkstra_shortest_paths` does. Previously they
  errored on graphs with unreachable vertices
  ([#179](https://github.com/ITensor/NamedGraphs.jl/pull/179)).
