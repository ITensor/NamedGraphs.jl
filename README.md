# NamedGraphs



[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://mtfishman.github.io/NamedGraphs.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://mtfishman.github.io/NamedGraphs.jl/dev)
[![Build Status](https://github.com/mtfishman/NamedGraphs.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/mtfishman/NamedGraphs.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/mtfishman/NamedGraphs.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/mtfishman/NamedGraphs.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)



## Installation



You can install the package using Julia's package manager:
```julia
julia> ] add NamedGraphs
```



## Introduction



This packages introduces graph types with named edges, which are built on top of the `Graph`/`SimpleGraph` type in the [Graphs.jl](https://github.com/JuliaGraphs/Graphs.jl) package that only have contiguous integer edges (i.e. linear indexing).



There is a supertype `AbstractNamedGraph` that defines an interface and fallback implementations of standard
Graphs.jl operations, and two implementations: `NamedGraph` and `NamedDiGraph`.



## `NamedGraph`



`NamedGraph` simply takes a set of names for the vertices of the graph. For example:

```julia
julia> using Graphs

julia> using NamedGraphs

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


julia> g = NamedGraph(grid((4,)); vertices=["A", "B", "C", "D"]) # Same as above
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

julia> neighbors(g, "B")
2-element Vector{String}:
 "A"
 "C"

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



It is natural to use tuples of integers as the names for the vertices of graphs with grid connectivities.
For this, we use the convention that if a tuple is input, it is interpreted as the grid size and
the vertex names label cartesian coordinates:

```julia
julia> g = NamedGraph(grid((2, 2)); vertices=(2, 2))
NamedGraph{Tuple{Int64, Int64}} with 4 vertices:
4-element Vector{Tuple{Int64, Int64}}:
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



Vertices can be referred to by their tuples:

```julia
julia> has_vertex(g, (1, 1))
true

julia> has_edge(g, (1, 1) => (2, 1))
true

julia> has_edge(g, (1, 1) => (2, 2))
false

julia> neighbors(g, (2, 2))
2-element Vector{Tuple{Int64, Int64}}:
 (2, 1)
 (1, 2)
```


You can use vertex names to get [induced subgraphs](https://juliagraphs.org/Graphs.jl/dev/core_functions/operators/#Graphs.induced_subgraph-Union{Tuple{T},%20Tuple{U},%20Tuple{T,%20AbstractVector{U}}}%20where%20{U%3C:Integer,%20T%3C:AbstractGraph}):

```julia
julia> subgraph(v -> v[1] == 1, g)
NamedGraph{Tuple{Int64, Int64}} with 2 vertices:
2-element Vector{Tuple{Int64, Int64}}:
 (1, 1)
 (1, 2)

and 1 edge(s):
(1, 1) => (1, 2)


julia> subgraph(v -> v[2] == 2, g)
NamedGraph{Tuple{Int64, Int64}} with 2 vertices:
2-element Vector{Tuple{Int64, Int64}}:
 (1, 2)
 (2, 2)

and 1 edge(s):
(1, 2) => (2, 2)


julia> g[[(1, 1), (2, 2)]]
NamedGraph{Tuple{Int64, Int64}} with 2 vertices:
2-element Vector{Tuple{Int64, Int64}}:
 (1, 1)
 (2, 2)

and 0 edge(s):

```


Note that this is similar to multidimensional array slicing, and we may support syntax like `subgraph(v, 1, :)` in the future.



You can also take [disjoint unions](https://en.wikipedia.org/wiki/Disjoint_union) or concatenations of graphs:

```julia
julia> g₁ = g
NamedGraph{Tuple{Int64, Int64}} with 4 vertices:
4-element Vector{Tuple{Int64, Int64}}:
 (1, 1)
 (2, 1)
 (1, 2)
 (2, 2)

and 4 edge(s):
(1, 1) => (2, 1)
(1, 1) => (1, 2)
(2, 1) => (2, 2)
(1, 2) => (2, 2)


julia> g₂ = g
NamedGraph{Tuple{Int64, Int64}} with 4 vertices:
4-element Vector{Tuple{Int64, Int64}}:
 (1, 1)
 (2, 1)
 (1, 2)
 (2, 2)

and 4 edge(s):
(1, 1) => (2, 1)
(1, 1) => (1, 2)
(2, 1) => (2, 2)
(1, 2) => (2, 2)


julia> disjoint_union(g₁, g₂)
NamedGraph{Tuple{Tuple{Int64, Int64}, Int64}} with 8 vertices:
8-element Vector{Tuple{Tuple{Int64, Int64}, Int64}}:
 ((1, 1), 1)
 ((2, 1), 1)
 ((1, 2), 1)
 ((2, 2), 1)
 ((1, 1), 2)
 ((2, 1), 2)
 ((1, 2), 2)
 ((2, 2), 2)

and 8 edge(s):
((1, 1), 1) => ((2, 1), 1)
((1, 1), 1) => ((1, 2), 1)
((2, 1), 1) => ((2, 2), 1)
((1, 2), 1) => ((2, 2), 1)
((1, 1), 2) => ((2, 1), 2)
((1, 1), 2) => ((1, 2), 2)
((2, 1), 2) => ((2, 2), 2)
((1, 2), 2) => ((2, 2), 2)


julia> g₁ ⊔ g₂ # Same as above
NamedGraph{Tuple{Tuple{Int64, Int64}, Int64}} with 8 vertices:
8-element Vector{Tuple{Tuple{Int64, Int64}, Int64}}:
 ((1, 1), 1)
 ((2, 1), 1)
 ((1, 2), 1)
 ((2, 2), 1)
 ((1, 1), 2)
 ((2, 1), 2)
 ((1, 2), 2)
 ((2, 2), 2)

and 8 edge(s):
((1, 1), 1) => ((2, 1), 1)
((1, 1), 1) => ((1, 2), 1)
((2, 1), 1) => ((2, 2), 1)
((1, 2), 1) => ((2, 2), 1)
((1, 1), 2) => ((2, 1), 2)
((1, 1), 2) => ((1, 2), 2)
((2, 1), 2) => ((2, 2), 2)
((1, 2), 2) => ((2, 2), 2)

```


The symbol `⊔` is just an alias for `disjoint_union` and can be written in the terminal
or in your favorite [ide with the appropriate Julia extension](https://julialang.org/) with `\sqcup<tab>`



By default, this maps the vertices `v₁ ∈ vertices(g₁)` to `(v₁, 1)` and the vertices `v₂ ∈ vertices(g₂)`
to `(v₂, 1)`, so the resulting vertices of the unioned graph will always be unique.
The resulting graph will have no edges between vertices `(v₁, 1)` and `(v₂, 1)`, these would have to
be added manually.



The original graphs can be obtained from subgraphs:

```julia
julia> rename_vertices(v -> v[1], subgraph(v -> v[2] == 1, g₁ ⊔ g₂))
NamedGraph{Tuple{Int64, Int64}} with 4 vertices:
4-element Vector{Tuple{Int64, Int64}}:
 (1, 1)
 (2, 1)
 (1, 2)
 (2, 2)

and 4 edge(s):
(1, 1) => (2, 1)
(1, 1) => (1, 2)
(2, 1) => (2, 2)
(1, 2) => (2, 2)


julia> rename_vertices(v -> v[1], subgraph(v -> v[2] == 2, g₁ ⊔ g₂))
NamedGraph{Tuple{Int64, Int64}} with 4 vertices:
4-element Vector{Tuple{Int64, Int64}}:
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


## Generating this README



This file was generated with [weave.jl](https://github.com/JunoLab/Weave.jl) with the following commands:

```julia
using NamedGraphs, Weave
weave(joinpath(pkgdir(NamedGraphs), "examples", "README.jl"); doctype="github", out_path=pkgdir(NamedGraphs))
```
