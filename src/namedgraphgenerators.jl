using .GraphsExtensions: add_edges!, comb_tree
using Graphs.SimpleGraphs: AbstractSimpleGraph
using Graphs: IsDirected, bfs_tree, binary_tree, cycle_graph, grid, inneighbors,
    merge_vertices, nv, outneighbors, path_digraph, path_graph, rem_vertex!, rem_vertices!
using SimpleTraits: SimpleTraits, @traitfn, Not

## TODO: Bring this back in some form?
## TODO: Move to `GraphsExtensions`?
## @traitfn function parent(tree::AbstractSimpleGraph::IsDirected, v::Integer)
##   return only(inneighbors(tree, v))
## end

## TODO: Move to `GraphsExtensions`?
@traitfn function children(tree::AbstractSimpleGraph::IsDirected, v::Integer)
    return outneighbors(tree, v)
end

## TODO: Move to `GraphsExtensions`?
@traitfn function set_named_vertices!(
        vertex_names::AbstractVector,
        tree::AbstractSimpleGraph::IsDirected,
        simple_parent::Integer,
        named_parent;
        child_name = identity
    )
    simple_children = children(tree, simple_parent)
    for n in 1:length(simple_children)
        simple_child = simple_children[n]
        named_child = [named_parent; child_name(n)]
        vertex_names[simple_child] = named_child
        set_named_vertices!(vertex_names, tree, simple_child, named_child; child_name)
    end
    return vertex_names
end

# Each vertex is named by its path from the root, as a vector of child indices.
# k = 3:
# 1 => [1]
# 2 => [1, 1]
# 3 => [1, 2]
# 4 => [1, 1, 1]
# 5 => [1, 1, 2]
# 6 => [1, 2, 1]
# 7 => [1, 2, 2]
function named_bfs_tree_vertices(
        simple_graph::AbstractSimpleGraph, source::Integer = 1; source_name = 1,
        child_name = identity
    )
    tree = bfs_tree(simple_graph, source)
    named_source = [source_name]
    vertex_names = Vector{typeof(named_source)}(undef, nv(simple_graph))
    vertex_names[source] = named_source
    set_named_vertices!(vertex_names, tree, source, named_source; child_name)
    return vertex_names
end

function named_bfs_tree(
        simple_graph::AbstractSimpleGraph, source::Integer = 1; source_name = 1,
        child_name = identity
    )
    vertex_names =
        named_bfs_tree_vertices(simple_graph, source; source_name, child_name)
    return NamedGraph(simple_graph, vertex_names)
end

"""
    named_binary_tree(k::Integer)

A named binary tree of depth `k`, with each vertex named by the path from the
root as a vector of child indices: the root is `[1]`, its children are
`[1, 1]` and `[1, 2]`, and so on.
"""
function named_binary_tree(
        k::Integer, source::Integer = 1; source_name = 1, child_name = identity
    )
    simple_graph = binary_tree(k)
    return named_bfs_tree(simple_graph, source; source_name, child_name)
end

"""
    named_path_graph(dim::Integer)

A named path graph on the vertices `1:dim`.

# Examples

```jldoctest
julia> using Graphs: edges, vertices

julia> using NamedGraphs: named_path_graph

julia> g = named_path_graph(4);

julia> collect(vertices(g))
4-element Vector{Int64}:
 1
 2
 3
 4

julia> collect(edges(g))
3-element Vector{NamedEdge{Int64}}:
 1 => 2
 2 => 3
 3 => 4
```
"""
function named_path_graph(dim::Integer)
    return NamedGraph(path_graph(dim))
end

"""
    named_cycle_graph(dim::Integer)

A named cycle graph on the vertices `1:dim`.
"""
function named_cycle_graph(dim::Integer)
    return NamedGraph(cycle_graph(dim))
end

"""
    named_path_digraph(dim::Integer)

A named directed path graph on the vertices `1:dim`.
"""
function named_path_digraph(dim::Integer)
    return NamedDiGraph(path_digraph(dim))
end

"""
    named_grid(dims; periodic = false)
    named_grid(dim::Integer; periodic = false)

A named grid graph of size `dims`, with each vertex named by its coordinate
tuple, so the grid `named_grid((2, 2))` has vertices `(1, 1)`, `(2, 1)`,
`(1, 2)`, and `(2, 2)`. A single integer `dim` gives a one-dimensional grid on
the vertices `1:dim`. `periodic = true` connects the boundaries.

# Examples

```jldoctest
julia> using Graphs: edges, vertices

julia> using NamedGraphs: named_grid

julia> g = named_grid((2, 2));

julia> collect(vertices(g))
4-element Vector{Tuple{Int64, Int64}}:
 (1, 1)
 (2, 1)
 (1, 2)
 (2, 2)

julia> collect(edges(g))
4-element Vector{NamedEdge{Tuple{Int64, Int64}}}:
 (1, 1) => (2, 1)
 (1, 1) => (1, 2)
 (2, 1) => (2, 2)
 (1, 2) => (2, 2)
```
"""
function named_grid(dim::Integer; kwargs...)
    simple_graph = grid((dim,); kwargs...)
    return NamedGraph(simple_graph)
end

function named_grid(dims; kwargs...)
    simple_graph = grid(dims; kwargs...)
    return NamedGraph(simple_graph, Tuple.(CartesianIndices(Tuple(dims))))
end

"""
    named_comb_tree(dims::Tuple)
    named_comb_tree(tooth_lengths::AbstractVector{<:Integer})

A named comb tree with `dims[1]` teeth of length `dims[2]`, or teeth of the
given lengths, with each vertex named by its coordinate tuple: `(jx, jy)` is
the `jy`th vertex of tooth `jx`, and the `(jx, 1)` vertices form the backbone.

# Examples

```jldoctest
julia> using Graphs: edges, vertices

julia> using NamedGraphs: named_comb_tree

julia> g = named_comb_tree([2, 1]);

julia> collect(vertices(g))
3-element Vector{Tuple{Int64, Int64}}:
 (1, 1)
 (2, 1)
 (1, 2)

julia> collect(edges(g))
2-element Vector{NamedEdge{Tuple{Int64, Int64}}}:
 (1, 1) => (2, 1)
 (1, 1) => (1, 2)
```
"""
function named_comb_tree(dims::Tuple)
    simple_graph = comb_tree(dims)
    return NamedGraph(simple_graph, Tuple.(CartesianIndices(Tuple(dims))))
end

function named_comb_tree(tooth_lengths::AbstractVector{<:Integer})
    @assert all(>(0), tooth_lengths)
    simple_graph = comb_tree(tooth_lengths)
    nx = length(tooth_lengths)
    ny = maximum(tooth_lengths)
    vertices = filter(Tuple.(CartesianIndices((nx, ny)))) do (jx, jy)
        return jy <= tooth_lengths[jx]
    end
    return NamedGraph(simple_graph, vertices)
end

"""
    named_hexagonal_lattice_graph(m::Integer, n::Integer; periodic = false)

A named graph of a hexagonal tiling of the plane, with `m` rows and `n`
columns of hexagons and each vertex named by its coordinate tuple.
`periodic = true` tiles the torus instead. Based on the NetworkX generator
`hexagonal_lattice_graph`.
"""
function named_hexagonal_lattice_graph(m::Integer, n::Integer; periodic = false)
    M = 2 * m
    rows = [i for i in 1:(M + 2)]
    cols = [i for i in 1:(n + 1)]

    if periodic && (n % 2 == 1 || m < 2 || n < 2)
        error("Periodic Hexagonal Lattice needs m > 1, n > 1 and n even")
    end

    G = NamedGraph([(j, i) for i in cols for j in rows])

    col_edges = [(j, i) => (j + 1, i) for i in cols for j in rows[1:(M + 1)]]
    row_edges = [(j, i) => (j, i + 1) for i in cols[1:n] for j in rows if i % 2 == j % 2]
    add_edges!(G, col_edges)
    add_edges!(G, row_edges)
    rem_vertex!(G, (M + 2, 1))
    rem_vertex!(G, ((M + 1) * (n % 2) + 1, n + 1))

    if periodic == true
        for i in cols[1:n]
            G = merge_vertices(G, [(1, i), (M + 1, i)])
        end

        for i in cols[2:(n + 1)]
            G = merge_vertices(G, [(2, i), (M + 2, i)])
        end

        for j in rows[2:M]
            G = merge_vertices(G, [(j, 1), (j, n + 1)])
        end

        rem_vertex!(G, (M + 1, n + 1))
    end

    return G
end

"""
    named_triangular_lattice_graph(m::Integer, n::Integer; periodic = false)

A named graph of an equilateral triangle tiling of the plane, with `m` rows
and `n` columns of triangles and each vertex named by its coordinate tuple.
`periodic = true` tiles the torus instead. Based on the NetworkX generator
`triangular_lattice_graph`.
"""
function named_triangular_lattice_graph(m::Integer, n::Integer; periodic = false)
    N = floor(Int64, (n + 1) / 2.0)
    rows = [i for i in 1:(m + 1)]
    cols = [i for i in 1:(N + 1)]

    if periodic && (n < 5 || m < 3)
        error("Periodic Triangular Lattice needs m > 2, n > 4")
    end

    G = NamedGraph([(j, i) for i in cols for j in rows])

    grid_edges1 = [(j, i) => (j, i + 1) for j in rows for i in cols[1:N]]
    grid_edges2 = [(j, i) => (j + 1, i) for j in rows[1:m] for i in cols]
    add_edges!(G, vcat(grid_edges1, grid_edges2))

    diagonal_edges1 = [(j, i) => (j + 1, i + 1) for j in rows[2:2:m] for i in cols[1:N]]
    diagonal_edges2 = [(j, i + 1) => (j + 1, i) for j in rows[1:2:m] for i in cols[1:N]]
    add_edges!(G, vcat(diagonal_edges1, diagonal_edges2))

    if periodic == true
        for i in cols
            G = merge_vertices(G, [(1, i), (m + 1, i)])
        end

        for j in rows[1:m]
            G = merge_vertices(G, [(j, 1), (j, N + 1)])
        end

    elseif n % 2 == 1
        rem_vertices!(G, [(j, N + 1) for j in rows[2:2:(m + 1)]])
    end

    return G
end
