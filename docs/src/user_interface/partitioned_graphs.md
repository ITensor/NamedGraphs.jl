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
```

## Quotient vertices and edges

```@docs; canonical=false
QuotientVertex
quotientvertices
QuotientEdge
quotientedge
quotientedges
boundary_quotientedges
```
