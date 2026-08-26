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
NamedGraph
NamedDiGraph
NamedEdge
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
NamedGridGraph
```
