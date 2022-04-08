# NamedGraphs

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://mtfishman.github.io/NamedGraphs.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://mtfishman.github.io/NamedGraphs.jl/dev)
[![Build Status](https://github.com/mtfishman/NamedGraphs.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/mtfishman/NamedGraphs.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/mtfishman/NamedGraphs.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/mtfishman/NamedGraphs.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

## Introduction

This packages introduces graph types with named edges, which are built on top of the `Graph`/`SimpleGraph` type in the [Graphs.jl](https://github.com/JuliaGraphs/Graphs.jl) package that only have contiguous integer edges (i.e. linear indexing).

There is a supertype `AbstractNamedGraph` that defines an interface and fallback implementations of standard
Graphs.jl operations, and two implementations: `NamedGraph` and `MultiDimGraph`.

## `NamedGraph`

`NamedGraph` simply takes a set of names for the vertices of the graph. For example:
```julia
julia> using NamedGraphs
[ Info: Precompiling NamedGraphs [678767b0-92e7-4007-89e4-4527a8725b19]

julia> using Graphs

julia> g = NamedGraph(grid((4,)), ["A", "B", "C", "D"])
NamedGraph{String} with 4 vertices:
4-element Vector{String}:
 "A"
 "B"
 "C"
 "D"

and 3 edge(s):
"A" => "B"
"B" => "C"
"C" => "D"
```
Common operations are defined as you would expect:
```julia
julia> has_vertex(g, "A")
true

julia> has_edge(g, "A" => "B")
true

julia> has_edge(g, "A" => "C")
false

julia> g[["A", "B"]]
NamedGraph{String} with 2 vertices:
2-element Vector{String}:
 "A"
 "B"

and 1 edge(s):
"A" => "B"
```

Internally, this type wraps a `SimpleGraph`, and stores a `Dictionary` from the [Dictionaries.jl](https://github.com/andyferris/Dictionaries.jl) package that maps the vertex names to the linear indices of the underlying `SimpleGraph`.

Graph operations are implemented by mapping back and forth between the generalized named vertices and the linear index vertices of the `SimpleGraph`.

## `MultiDimGraph`

`MultiDimGraph` is very similar to a `NamedGraph` but a bit more sophisticated. It has generalized
multi-dimensional array indexing, mixed with named dimensions like [NamedDims.jl](https://github.com/invenia/NamedDims.jl).

This allows for more sophisticated behavior, such as slicing dimensions and [disjoint unions](https://en.wikipedia.org/wiki/Disjoint_union) (generalizations of array concatenations).

We start out by making a multi-dimensional graph where we specify the dimensions, which
assigns vertex labels based on cartesian coordinates:
```julia
julia> g = MultiDimGraph(grid((2, 2)); dims=(2, 2))
MultiDimGraph{Tuple} with 4 vertices:
4-element Vector{Tuple}:
 (1, 1)
 (2, 1)
 (1, 2)
 (2, 2)

and 4 edge(s):
(1, 1) => (2, 1)
(1, 1) => (1, 2)
(2, 1) => (2, 2)
(1, 2) => (2, 2)
```
Internally the vertices are all stored as tuples with a label in each dimension.

Vertices can be referred to by their tuples or splatted indices in each dimension:
```julia
julia> has_vertex(g, (1, 1))
true

julia> has_vertex(g, 1, 1)
true

julia> has_edge(g, (1, 1) => (2, 1))
true

julia> has_edge(g, (1, 1) => (2, 2))
false
```
This allows the graph to be treated partially as a set of named vertices and
partially with multi-dimensional array indexing syntax. For example
you can slice a dimension to get the [induced subgraph](https://juliagraphs.org/Graphs.jl/dev/core_functions/operators/#Graphs.induced_subgraph-Union{Tuple{T},%20Tuple{U},%20Tuple{T,%20AbstractVector{U}}}%20where%20{U%3C:Integer,%20T%3C:AbstractGraph}):
```julia
julia> g[1, :]
MultiDimGraph{Tuple} with 2 vertices:
2-element Vector{Tuple}:
 (1,)
 (2,)

and 1 edge(s):
(1,) => (2,)


julia> g[:, 2]
MultiDimGraph{Tuple} with 2 vertices:
2-element Vector{Tuple}:
 (1,)
 (2,)

and 1 edge(s):
(1,) => (2,)

julia> g[[(1, 1), (2, 2)]]
MultiDimGraph{Tuple} with 2 vertices:
2-element Vector{Tuple}:
 (1, 1)
 (2, 2)


and 0 edge(s):
```
Note that slicing drops the dimensions of single indices, just like Julia Array slicing:
```julia
julia> x = randn(2, 2)
2×2 Matrix{Float64}:
 1.15269   -0.234346
 0.533677   0.84083

julia> x[1, :]
2-element Vector{Float64}:
  1.1526938167214478
 -0.2343463636899781
```

Graphs can also take [disjoint unions](https://en.wikipedia.org/wiki/Disjoint_union) or concatenations of graphs:
```julia
julia> disjoint_union(g, g)
MultiDimGraph{Tuple} with 8 vertices:
8-element Vector{Tuple}:
 (1, 1, 1)
 (1, 2, 1)
 (1, 1, 2)
 (1, 2, 2)
 (2, 1, 1)
 (2, 2, 1)
 (2, 1, 2)
 (2, 2, 2)

and 8 edge(s):
(1, 1, 1) => (1, 2, 1)
(1, 1, 1) => (1, 1, 2)
(1, 2, 1) => (1, 2, 2)
(1, 1, 2) => (1, 2, 2)
(2, 1, 1) => (2, 2, 1)
(2, 1, 1) => (2, 1, 2)
(2, 2, 1) => (2, 2, 2)
(2, 1, 2) => (2, 2, 2)


julia> g ⊔ g
MultiDimGraph{Tuple} with 8 vertices:
8-element Vector{Tuple}:
 (1, 1, 1)
 (1, 2, 1)
 (1, 1, 2)
 (1, 2, 2)
 (2, 1, 1)
 (2, 2, 1)
 (2, 1, 2)
 (2, 2, 2)

and 8 edge(s):
(1, 1, 1) => (1, 2, 1)
(1, 1, 1) => (1, 1, 2)
(1, 2, 1) => (1, 2, 2)
(1, 1, 2) => (1, 2, 2)
(2, 1, 1) => (2, 2, 1)
(2, 1, 1) => (2, 1, 2)
(2, 2, 1) => (2, 2, 2)
(2, 1, 2) => (2, 2, 2)
```
The symbol `⊔` is just an alias for `disjoint_union` and can be written in the terminal
or in your favorite [ide with the appropriate Julia extension](https://julialang.org/) with `\sqcup<tab>`

Note that by default this introduces new dimension names (which by default are contiguous integers
starting from 1) in the first dimension of the graph, so we can get back
the original graphs by slicing and setting the first dimension:
```julia
julia> (g ⊔ g)[1, :]
MultiDimGraph{Tuple} with 4 vertices:
4-element Vector{Tuple}:
 (1, 1)
 (2, 1)
 (1, 2)
 (2, 2)

and 4 edge(s):
(1, 1) => (2, 1)
(1, 1) => (1, 2)
(2, 1) => (2, 2)
(1, 2) => (2, 2)


julia> (g ⊔ g)[2, :]
MultiDimGraph{Tuple} with 4 vertices:
4-element Vector{Tuple}:
 (1, 1)
 (2, 1)
 (1, 2)
 (2, 2)

and 4 edge(s):
(1, 1) => (2, 1)
(1, 1) => (1, 2)
(2, 1) => (2, 2)
(1, 2) => (2, 2)
```
or slice across the graphs that we disjoint unioned:
```julia
julia> (g ⊔ g)[:, 1, :]
MultiDimGraph{Tuple} with 4 vertices:
4-element Vector{Tuple}:
 (1, 1)
 (1, 2)
 (2, 1)
 (2, 2)

and 2 edge(s):
(1, 1) => (1, 2)
(2, 1) => (2, 2)
```

Additionally, we can use standard array concatenation syntax, such as:
```julia
julia> [g; g]
MultiDimGraph{Tuple} with 8 vertices:
8-element Vector{Tuple}:
 (1, 1)
 (2, 1)
 (1, 2)
 (2, 2)
 (3, 1)
 (4, 1)
 (3, 2)
 (4, 2)

and 8 edge(s):
(1, 1) => (2, 1)
(1, 1) => (1, 2)
(2, 1) => (2, 2)
(1, 2) => (2, 2)
(3, 1) => (4, 1)
(3, 1) => (3, 2)
(4, 1) => (4, 2)
(3, 2) => (4, 2)
```
which is equivalent to `vcat(g, g)` or:
```julia
julia> [g;; g]
MultiDimGraph{Tuple} with 8 vertices:
8-element Vector{Tuple}:
 (1, 1)
 (2, 1)
 (1, 2)
 (2, 2)
 (1, 3)
 (2, 3)
 (1, 4)
 (2, 4)

and 8 edge(s):
(1, 1) => (2, 1)
(1, 1) => (1, 2)
(2, 1) => (2, 2)
(1, 2) => (2, 2)
(1, 3) => (2, 3)
(1, 3) => (1, 4)
(2, 3) => (2, 4)
(1, 4) => (2, 4)
```
which is the same as `hcat(g, g)`.
