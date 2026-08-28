# Named graphs

```@meta
CurrentModule = NamedGraphs
CollapsedDocStrings = true
```

Named graphs implement the Graphs.jl interface with vertices of arbitrary
type: functions like `add_edge!`, `has_edge`, `neighbors`, and `vertices` take
and return the vertex names. `NamedGraph` and `NamedDiGraph` are the
undirected and directed graph types, with edges of type `NamedEdge`.

```@docs; canonical=false
AbstractNamedGraph
NamedGraph
NamedDiGraph
NamedEdge
```

## Graph functionality

Most functionality comes from Graphs.jl itself and is documented there. Listed
here are the functions whose named graph behaviour is worth knowing about, along
with extensions NamedGraphs adds that work on any `Graphs.AbstractGraph`. This
section will grow over time.

```@docs; canonical=false
vertices(::AbstractNamedGraph)
edges(::AbstractNamedGraph)
neighbors(::AbstractNamedGraph, ::Any)
subgraph
incident_edges
Graphs.add_vertices!(::AbstractNamedGraph, ::Any)
add_vertices
Graphs.rem_vertices!(::AbstractNamedGraph, ::Any)
rem_vertices
add_edges!
add_edges
rem_edges!(::AbstractNamedGraph, ::Any)
rem_edges
```

## Generators

Constructors for commonly used named graphs.

```@docs; canonical=false
named_grid
named_path_graph
named_cycle_graph
named_path_digraph
named_binary_tree
named_comb_tree
named_hexagonal_lattice_graph
named_triangular_lattice_graph
```
