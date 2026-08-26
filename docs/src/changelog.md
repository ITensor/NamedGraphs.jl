# Changelog

## [0.14.0](https://github.com/ITensor/NamedGraphs.jl/compare/v0.13.0...main) - Unreleased

NamedGraphs v0.14 reworks how named vertices and edges are translated to the
integer vertices and edges used internally. The changes are mildly breaking:
some output types change when you call `vertices` and `edges`, and the
overload points for defining a new `AbstractNamedGraph` are renamed.

### Breaking changes

#### Encode and decode terminology

The "position graph" terminology is replaced with encode and decode
terminology
([#178](https://github.com/ITensor/NamedGraphs.jl/pull/178)).
Converting a named vertex or edge to the corresponding integer
vertex or edge is called encoding, and the reverse is called decoding. The
minimal overloads for implementing a new `AbstractNamedGraph` are:

  - `encoded_graph(g)`, the graph on the integer vertices `1:nv(g)` (replaces
    `position_graph`, with a generic fallback `EncodedGraphView` so a graph
    type does not need to store an integer graph),
  - `encode_vertex(g, v)`, the integer code of vertex `v` (replaces
    `vertex_positions`),
  - `decode_vertex(g, c)`, the vertex with integer code `c` (replaces
    `ordered_vertices`).

Codes are not stable across mutation: adding or removing vertices may
reassign the codes of other vertices.

#### Ordinal indexing is removed

The `OrdinalIndexing` submodule is removed, so `vertices(g)[4th]` becomes
`decode_vertex(g, 4)`
([#178](https://github.com/ITensor/NamedGraphs.jl/pull/178)).

#### Output of `vertices`

`vertices(g::NamedGraph)` (and `NamedDiGraph`) outputs a
`Dictionaries.Indices` instead of the internal `OrderedIndices` type, which is
removed along with the `OrderedDictionaries` submodule
([#178](https://github.com/ITensor/NamedGraphs.jl/pull/178)). Other
`AbstractNamedGraph` types can output other `AbstractIndices` set views. The
output is a live read-only view of the graph with fast membership testing,
and `map` over it outputs a `Dictionary` keyed by the vertices.

The vertices iterate in insertion order, which is stable under removals. For
example, removing `"v2"` from a graph with vertices `["v1", "v2", "v3", "v4"]`
iterates as `["v1", "v3", "v4"]` (previously the last vertex was swapped into
the removed slot, giving `["v1", "v4", "v3"]`). The iteration order therefore
no longer matches the integer codes after removals, so code that aligns
`vertices(g)` with results computed on the integer graph should translate
through `decode_vertex`.

#### Output of `edges`

`edges(g)` outputs a lazy iterator instead of an instantiated `Vector`, like
`edges(::SimpleGraph)` does in Graphs.jl
([#178](https://github.com/ITensor/NamedGraphs.jl/pull/178)). Membership
(`in`) matches `has_edge`, and `==` between two edge iterators compares the
edge sets. Code that indexed into the output or compared it against a
`Vector` should `collect` it first.

#### Concrete `NamedGraph` and `NamedDiGraph` types

`GenericNamedGraph{V, G}` is removed
([#179](https://github.com/ITensor/NamedGraphs.jl/pull/179)). It was not
exported, so this only affects code that imported it explicitly.
`NamedGraph{V}` and `NamedDiGraph{V}` are now separately defined concrete
types, hardcoded to `SimpleGraph{Int}` and `SimpleDiGraph{Int}` underlying
storage. In practice those were the only instantiations, and the extra type
parameter leaked into type signatures and printing. Graph types not backed by
a stored integer graph implement the `encode_vertex`/`decode_vertex`
interface directly instead.

#### Mutation functions return `Bool`

`rem_vertex!`, `add_edge!`, and `rem_edge!` return `true` or `false` following
Graphs.jl, matching `add_vertex!`
([#179](https://github.com/ITensor/NamedGraphs.jl/pull/179)). Previously they
returned the graph on success, and `add_edge!`/`rem_edge!` threw for edges
with vertices not in the graph, which now returns `false`.

### Non-breaking changes

#### Unreachable vertices in `bfs_parents` and `dfs_parents`

`bfs_parents(g, v)` and `dfs_parents(g, v)` map vertices unreachable from `v`
to themselves, like `dijkstra_shortest_paths` does
([#179](https://github.com/ITensor/NamedGraphs.jl/pull/179)). Previously they
errored on graphs with unreachable vertices.
