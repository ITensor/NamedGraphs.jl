# Partitioned graphs

```@meta
CurrentModule = NamedGraphs.PartitionedGraphs
CollapsedDocStrings = true
```

The `NamedGraphs.PartitionedGraphs` module provides types and functions for
graphs whose vertices are grouped into a partition, and for the quotient
graphs those partitions induce.

```@docs; canonical=false
PartitionedGraphs
AbstractPartitionedGraph
```

## Partitioned graph types

```@docs; canonical=false
PartitionedGraph
PartitionedView
partitionedgraph
departition
unpartition
```

## Quotient graphs

```@docs; canonical=false
QuotientView
quotientview
```

## Quotient vertices and edges

```@docs; canonical=false
QuotientVertex
quotientvertices
has_quotientvertex
rem_quotientvertex!
QuotientEdge
quotientedge
quotientedges
has_quotientedge
rem_quotientedge!
boundary_quotientedges
is_partition_boundary_edge
```
