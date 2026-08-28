using Graphs: AbstractGraph, dst, src, vertices

# https://en.wikipedia.org/wiki/Boundary_(graph_theory)
"""
    boundary_edges(graph::AbstractGraph, subgraph_vertices; dir=:out)

The edges of `graph` with one endpoint in `subgraph_vertices` and the other
outside of it. `dir` orients the returned edges as in [`incident_edges`](@ref),
so by default each one points from the vertex inside to the vertex outside.

The result may be a view into `graph` rather than freshly allocated storage:
do not modify it, and do not use it after mutating `graph`. Its concrete
`AbstractVector` type is not part of the interface.

# Examples

```jldoctest
julia> using NamedGraphs: NamedEdge, boundary_edges, named_grid

julia> g = named_grid((2, 2));

julia> es = boundary_edges(g, [(1, 1), (1, 2)]);

julia> issetequal(es, [NamedEdge((1, 1) => (2, 1)), NamedEdge((1, 2) => (2, 2))])
true
```
"""
function boundary_edges(graph::AbstractGraph, subgraph_vertices; dir = :out)
    E = edgetype(graph)
    subgraph_vertices_set = Set(subgraph_vertices)
    subgraph_complement = setdiff(Set(vertices(graph)), subgraph_vertices_set)
    boundary_es = Vector{E}()
    for subgraph_vertex in subgraph_vertices_set
        for e in incident_edges(graph, subgraph_vertex; dir)
            if src(e) ∈ subgraph_complement || dst(e) ∈ subgraph_complement
                push!(boundary_es, e)
            end
        end
    end
    return boundary_es
end

# https://en.wikipedia.org/wiki/Boundary_(graph_theory)
# See implementation of `Graphs.neighborhood_dists` as a reference.
function inner_boundary_vertices(graph::AbstractGraph, subgraph_vertices; dir = :out)
    V = vertextype(graph)
    subgraph_vertices_set = Set(subgraph_vertices)
    subgraph_complement = setdiff(Set(vertices(graph)), subgraph_vertices_set)
    inner_boundary_vs = Vector{V}()
    for subgraph_vertex in subgraph_vertices_set
        for subgraph_vertex_neighbor in _neighbors(graph, subgraph_vertex; dir)
            if subgraph_vertex_neighbor ∈ subgraph_complement
                push!(inner_boundary_vs, subgraph_vertex)
                break
            end
        end
    end
    return inner_boundary_vs
end

# https://en.wikipedia.org/wiki/Boundary_(graph_theory)
# See implementation of `Graphs.neighborhood_dists` as a reference.
function outer_boundary_vertices(graph::AbstractGraph, subgraph_vertices; dir = :out)
    V = vertextype(graph)
    subgraph_vertices_set = Set(subgraph_vertices)
    subgraph_complement = setdiff(Set(vertices(graph)), subgraph_vertices_set)
    outer_boundary_vs = Set{V}()
    for subgraph_vertex in subgraph_vertices_set
        for subgraph_vertex_neighbor in _neighbors(graph, subgraph_vertex; dir)
            if subgraph_vertex_neighbor ∈ subgraph_complement
                push!(outer_boundary_vs, subgraph_vertex_neighbor)
            end
        end
    end
    return [v for v in outer_boundary_vs]
end

function boundary_vertices(graph::AbstractGraph, subgraph_vertices; dir = :out)
    return inner_boundary_vertices(graph, subgraph_vertices; dir)
end
