```@meta
EditURL = "../../examples/README.jl"
```

# NamedGraphs.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://itensor.github.io/NamedGraphs.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://itensor.github.io/NamedGraphs.jl/dev/)
[![Build Status](https://github.com/ITensor/NamedGraphs.jl/actions/workflows/Tests.yml/badge.svg?branch=main)](https://github.com/ITensor/NamedGraphs.jl/actions/workflows/Tests.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/ITensor/NamedGraphs.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/ITensor/NamedGraphs.jl)
[![Code Style](https://img.shields.io/badge/code_style-ITensor-purple)](https://github.com/ITensor/ITensorFormatter.jl)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

NamedGraphs.jl is an extension of [Graphs.jl](https://github.com/JuliaGraphs/Graphs.jl)
providing graph types with named vertices. The vertices of a `NamedGraph` or
`NamedDiGraph` can be strings, tuples, or any other names, rather than the
contiguous integers of a `SimpleGraph`. The goal is for named graphs to
implement the functionality of Graphs.jl accounting for named vertices and
edges, so see the [Graphs.jl documentation](https://juliagraphs.org/Graphs.jl/stable/)
for the available functionality and interface. Note that reaching feature
parity with Graphs.jl is still in progress: for performance, functionality
is often implemented by translating to the integer vertices and forwarding
to the Graphs.jl implementation, which often assumes simple graphs
(contiguous 1-based integer vertices), so functions need to be wrapped one
by one. Please raise an issue if functionality you need is missing. The
package also includes tools for working with partitioned graphs and their
quotient graphs, and generic extensions of the Graphs.jl interface.

[DataGraphs.jl](https://github.com/ITensor/DataGraphs.jl) builds on top of
this package to provide named graphs with data associated with the vertices
and edges.

## Support

```@raw html
<img class="display-light-only" src="assets/CCQ.png" width="20%" alt="Flatiron Center for Computational Quantum Physics logo."/>
<img class="display-dark-only" src="assets/CCQ-dark.png" width="20%" alt="Flatiron Center for Computational Quantum Physics logo."/>
```


NamedGraphs.jl is supported by the Flatiron Institute, a division of the Simons Foundation.

## Installation instructions

The package can be added as usual through the package manager:

```julia
julia> Pkg.add("NamedGraphs")
```

## Examples

````@example index
using Graphs: add_edge!, has_edge, has_vertex, ne, neighbors, nv, path_graph, vertices
using NamedGraphs: NamedGraph
using Test: @test
````

Construct a graph with named vertices:

````@example index
g = NamedGraph(["a", "b", "c", "d"])
@test has_vertex(g, "a")
@test !has_vertex(g, "e")
@test nv(g) == 4
````

Add and check edges using the vertex names:

````@example index
add_edge!(g, "a" => "b")
add_edge!(g, "b" => "c")
@test has_edge(g, "a" => "b")
@test has_edge(g, "b" => "a")
@test !has_edge(g, "a" => "c")
@test ne(g) == 2
````

Graphs.jl functions take and return the vertex names:

````@example index
@test issetequal(neighbors(g, "b"), ["a", "c"])
@test collect(vertices(g)) == ["a", "b", "c", "d"]
````

The edge structure can also be supplied by a simple graph, with the `i`th
vertex name corresponding to the vertex `i` of the simple graph:

````@example index
g = NamedGraph(path_graph(4), ["a", "b", "c", "d"])
@test ne(g) == 3
@test has_edge(g, "a" => "b")
````

## Contributors

This package is primarily developed by:

- [Matt Fishman](https://github.com/mtfishman)
- [Joey Tindall](https://github.com/JoeyT1994)
- [Jack Dunham](https://github.com/jack-dunham)

See the [contributors page](https://github.com/ITensor/NamedGraphs.jl/graphs/contributors)
for the full list of contributors.

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

