# Changelog

## [0.14.0](https://github.com/ITensor/NamedGraphs.jl/compare/v0.13.0...main) - Unreleased

Reworks how named vertices and edges are translated to the integer vertices
and edges used internally.

### Upgrading

These are the changes that existing code actually runs into, ordered by how
often they came up when migrating the packages that depend on NamedGraphs. The
"Other breaking changes" section below has the rest.

#### The submodules are gone

`GraphsExtensions`, `Keys`, `SimilarType`, `GraphGenerators`,
`NamedGraphGenerators`, `OrdinalIndexing`, and `OrderedDictionaries` no longer
exist. `PartitionedGraphs` is the only remaining submodule. Their contents are
available directly from `NamedGraphs`, so an import like

```julia
using NamedGraphs.GraphsExtensions: boundary_edges
using NamedGraphs.NamedGraphGenerators: named_grid
```

becomes

```julia
using NamedGraphs: boundary_edges, named_grid
```

This is the most common change by volume and the least interesting: it fails
loudly at load with an `UndefVarError` naming the submodule, and the fix is to
delete the submodule from the path. Two cases need more than that:

- The `Key` type is deleted rather than moved. Contraction sequences over
  non-scalar vertices are built on it, so code that used it needs its own
  equivalent, along with a `NamedGraphs.to_graph_index(graph, key::Key)` method
  so the graph knows how to unwrap it.
- `vertices(g)[4th]` from `OrdinalIndexing` becomes `decoded_vertex(g, 4)`.

([#183](https://github.com/ITensor/NamedGraphs.jl/pull/183),
[#187](https://github.com/ITensor/NamedGraphs.jl/pull/187),
[#189](https://github.com/ITensor/NamedGraphs.jl/pull/189),
[#190](https://github.com/ITensor/NamedGraphs.jl/pull/190))

#### `edges(g)` returns a lazy iterator

`edges(g)` now returns a `Graphs.AbstractEdgeIter` rather than a `Vector`,
matching `edges(::SimpleGraph)` in Graphs.jl. Membership (`in`) matches
`has_edge`, and `==` between two edge iterators compares the edge sets.

Most of the resulting errors do not mention `edges`, so they are worth listing
by symptom:

| what you wrote | what you get |
|---|---|
| `filter(f, edges(g))` | `MethodError: no method matching filter(::F, ::NamedGraphs.NamedEdgeIter{...})` |
| `findfirst(f, edges(g))` | `MethodError: no method matching keys(::NamedGraphs.NamedEdgeIter{...})` |
| `edges(g)[i]` | `MethodError: no method matching getindex(::NamedGraphs.NamedEdgeIter{...}, ::Int64)` |
| a `Vector{<:AbstractEdge}` argument defaulting to `edges(g)` | a `MethodError` naming a generated keyword-body function rather than the function you called |

Adding `collect` at the call site fixes all of these.

Plenty still works directly, so there is no need to `collect` defensively:
iteration, `length`, `first`, `in`, `==`, `issetequal`, `union`, `setdiff`,
broadcasting (`reverse.(edges(g))` gives a properly typed `Vector`), and
building a `Dictionary` or `Indices` from the result.

**One case changes behavior instead of erroring.** `vcat` treats anything that
is not an `AbstractArray` as a single scalar element, so

```julia
julia> vcat(edges(g), reverse.(edges(g)))
5-element Vector{Any}:
 NamedEdge{Tuple{Int64, Int64}}[(1, 1) => (2, 1), (1, 1) => (1, 2), (2, 1) => (2, 2), (1, 2) => (2, 2)]
 (2, 1) => (1, 1)
 (1, 2) => (1, 1)
 (2, 2) => (2, 1)
 (2, 2) => (1, 2)
```

gives five elements on a four-edge graph, the first of which is the whole edge
list, where the intended result has eight. `collect` the first argument.

**`edges(g)` is also a live view of the graph rather than a snapshot.** Holding
on to it across a mutation now sees the mutation:

```julia
julia> es = edges(g); length(es)
4

julia> rem_edge!(g, first(es)); length(es)
3
```

`collect` it first if you need the edges as they were.

([#178](https://github.com/ITensor/NamedGraphs.jl/pull/178))

#### Vertex order and integer codes diverge after a removal

`vertices(g::Named[Di]Graph)` outputs a `Dictionaries.Indices` instead of the
internal `OrderedIndices` type. Other `AbstractNamedGraph` types can output
other `AbstractIndices` set views. Indexing is by vertex name, not position.

Vertices iterate in insertion order, which is stable under removals. The
integer codes are not: removing a vertex moves the last code into the freed
slot. In v0.13 those two orders were kept in agreement, and in v0.14 they part
company after the first removal:

```julia
julia> g = NamedGraph(path_graph(5), ["a", "b", "c", "d", "e"]); rem_vertex!(g, "b");

julia> collect(vertices(g))
4-element Vector{String}:
 "a"
 "c"
 "d"
 "e"

julia> [decoded_vertex(g, code) for code in 1:nv(g)]
4-element Vector{String}:
 "a"
 "e"
 "c"
 "d"
```

Nothing errors here, so code that computes something on the integer graph and
then maps the result back with `collect(vertices(g))[code]` silently gets the
wrong vertex. Translate through `decoded_vertex(g, code)` instead.

([#178](https://github.com/ITensor/NamedGraphs.jl/pull/178))

#### `encoded_graph` and friends replace the position graph

The "position graph" terminology is replaced with encode and decode
terminology. The overloads for implementing a new `AbstractNamedGraph` are
`encoded_graph(g)` (replaces `position_graph`, with a generic `EncodedGraphView`
fallback so a graph type does not need to store an integer graph),
`encoded_vertex(g, v)` (replaces `vertex_positions`), and `decoded_vertex(g, c)`
(replaces `ordered_vertices`). Codes are not stable across mutation.

This is not a symbol-level rename. `vertex_positions(g)` and
`ordered_vertices(g)` returned a whole mapping, while `encoded_vertex(g, v)` and
`decoded_vertex(g, c)` translate a single vertex, so a type that forwarded the
old three in a loop over function names has to write the new ones out as
separate methods.

([#178](https://github.com/ITensor/NamedGraphs.jl/pull/178))

#### Mutators return `Bool` and counts

`rem_vertex!`, `add_edge!`, and `rem_edge!` return `true` or `false` following
Graphs.jl, matching `add_vertex!`. Previously they returned the graph, and
`add_edge!`/`rem_edge!` threw for edges with vertices not in the graph, which
now returns `false`.

The plural mutators `add_edges!`, `rem_edges!`, `add_vertices!`, and
`rem_vertices!` return the number of successful additions or removals, where
they previously returned the graph. `Bool` from the singular `Graphs.add_edge!`
is the one-element case of the same count, and `Graphs.add_vertices!` already
returned a count. `rem_quotientvertex!` and `rem_quotientedge!` likewise return
how many underlying vertices or edges went, so `0` means the quotient vertex or
edge was not there.

This affects types that define these methods rather than code that calls them.
A type of that kind needs two things beyond the return value: a `has_vertex`
guard so that removing an absent vertex returns `false` instead of throwing,
and `Dictionaries.unset!` in place of `delete!` where a missing key would
otherwise throw.

([#179](https://github.com/ITensor/NamedGraphs.jl/pull/179),
[#188](https://github.com/ITensor/NamedGraphs.jl/pull/188))

### Other breaking changes

- `GenericNamedGraph{V, G}` is removed (it was not exported, so this only
  affects code that imported it explicitly). `NamedGraph{V}` and
  `NamedDiGraph{V}` are now separately defined concrete types, hardcoded to
  `SimpleGraph{Int}` and `SimpleDiGraph{Int}` underlying storage
  ([#179](https://github.com/ITensor/NamedGraphs.jl/pull/179)).
- `add_vertices!` and `rem_vertices!` are methods of the Graphs.jl functions of
  those names rather than separate functions of NamedGraphs' own, and are
  declared on `AbstractNamedGraph`. An integer second argument is a vertex name
  here, not upstream's count of vertices to append, since a named graph cannot
  invent names ([#188](https://github.com/ITensor/NamedGraphs.jl/pull/188)).
- Considerably more names are exported, where previously only the four graph and
  edge types were, so `using NamedGraphs` can collide with names another package
  exports ([#188](https://github.com/ITensor/NamedGraphs.jl/pull/188)).
- The wrappers around Graphs.jl functions mirror the upstream positional
  signatures instead of taking `args...` or untyped arguments, so some argument
  types that were previously accepted no longer are
  ([#186](https://github.com/ITensor/NamedGraphs.jl/pull/186)).
- `eccentricity(graph, x)` is always the eccentricity of the single vertex `x`.
  The every-vertex form is `eccentricities`
  ([#186](https://github.com/ITensor/NamedGraphs.jl/pull/186)).
- A `Vector{Bool}` passed to `induced_subgraph` is a list of vertex names, not a
  mask over `1:nv(graph)`, and `induced_subgraph` throws for vertices the graph
  does not have, where it previously returned a graph built on them
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
- `all_edges` is documented and exported, and reports its `eltype` and `length`
  correctly. It previously advertised `eltype` of `Any` and threw from `length`
  on undirected graphs ([#192](https://github.com/ITensor/NamedGraphs.jl/pull/192)).
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
