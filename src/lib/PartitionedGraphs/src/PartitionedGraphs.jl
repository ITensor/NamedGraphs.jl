"""
    module PartitionedGraphs

A library for partitioned graphs and their quotients.

This module provides data structures and functionalities to work with partitioned graphs,
including quotient vertices and edges, as well as views of partitioned graphs.
It defines an abstract supertype [`AbstractPartitionedGraph`](@ref) for graphs that have
some notion of a non-trivial partitioning of their vertices. It also provides 
a interface of functions that can be overloaded on any subtype of `Graphs.AbstractGraph` to
make this subtype behave like a partitioned graph, without itself subtyping [`AbstractPartitionedGraph`](@ref).

It defines the following concrete types:
- [`QuotientVertex`](@ref): Represents a vertex in the quotient graph.
- [`QuotientEdge`](@ref): Represents an edge in the quotient graph.
- [`PartitionedView`](@ref): A lightweight view of a partitioned graph.
- [`PartitionedGraph`](@ref): An implementation of a partitioned graph with extra caching
    not provided by [`PartitionedView`](@ref).
- [`QuotientView`](@ref): A view of the quotient graph derived from a partitioned graph.
It provides the following functions:
- [`partitionedgraph`](@ref): Partitions an `AbstractGraph`.
- [`departition`](@ref): Removes a single layer of partitioning from a partitioned graph.
- [`unpartition`](@ref): Recursively removes all layers of partitioning from a partitioned graph.

## Interfaces

For a type `MyGraphType{V} <: Graphs.AbstractGraph{V}`, to have a non-trivial partitioning
then the interface can be summarized as follows:
```julia
# 1. If you want a non-trivial partitioning, then overload the method:
partitioned_vertices(g::MyGraphType)

# 2a. For fast quotient graph construction and fast `has_edge` at the quotient_graph level:
quotient_graph(g::MyGraphType)
# 2b. If Julia is unable to infer the returned type of `quotient_graph` then you should
# also define the `quotient_graph_type` function:
quotient_graph_type(g::MyGraphType)

# 3. For a fast vertex to quotient-vertex map then:
quotientvertex(g::MyGraphType, vertex)
# ...which automatically gives a fast edge to quotient-edge map via:
quotientedge(g, edge) # no need to overload this.

# 4. For fast finding of edge partitions: 
partitioned_edges(g::MyGraphType)
```
If any of the above properties are desirable for MyGraphType, then store the data in a 
field and overload the associated function to get that field, e.g.
```julia
quotientvertex(g::MyGraphType, vertex) = g.inverse_vertex_map[vertex]
```
where we have chosen to store the map in the field `inverse_vertex_map` of the `MyGraphType` type. 
Doing this is not essential as everything can and will be derived from `partitioned_vertices`
as a fallback.

### Interface for adding and removing vertices

For a given partitioned graph, all vertices must live in a quotient vertex and there should
be no empty quotient vertices. The methods:
```julia
Graphs.rem_vertex!(g::MyGraphType, vertex)
Graphs.add_edge!(g::MyGraphType, edge)
Graphs.rem_edge!(g::MyGraphType, edge)
```
should be overloaded to ensure that these properties are maintained for the particular 
implementation of `MyGraphType`. 
Note, that the method:
```julia
Graphs.add_vertex!(g::MyGraphType, vertex)
```
is not supported for partitioned graphs as it is ambiguous which quotient vertex the new vertex
should belong to. To add a vertex to a partitioned graph, one should define the method:
```julia
Graphs.add_subquotientvertex!(g::MyGraphType, quotientvertex::QuotientVertex, vertex)
```
Doing so enables the syntax:
```julia
Graphs.add_vertex!(graph, QuotientVertex(quotientvertex)[vertex])
```
for adding `vertex` to the quotient vertex `quotientvertex` in the partitioned
graph.
"""
module PartitionedGraphs
include("quotientvertex.jl")
include("subquotientvertex.jl")
include("quotientedge.jl")
include("abstractpartitionedgraph.jl")
include("partitionedview.jl")
include("partitionedgraph.jl")
include("quotientview.jl")
end
