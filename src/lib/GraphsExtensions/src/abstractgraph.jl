using Dictionaries: Dictionary, Indices, dictionary
using Graphs:
    Graphs,
    AbstractEdge,
    AbstractGraph,
    IsDirected,
    Δ,
    a_star,
    add_edge!,
    add_vertex!,
    degree,
    dfs_tree,
    eccentricity,
    edgetype,
    has_edge,
    has_vertex,
    indegree,
    induced_subgraph,
    inneighbors,
    is_connected,
    is_cyclic,
    is_directed,
    is_tree,
    outdegree,
    outneighbors,
    ne,
    neighbors,
    nv,
    rem_edge!,
    rem_vertex!,
    weights
using SimpleTraits: SimpleTraits, Not, @traitfn
using SplitApplyCombine: groupfind

not_implemented() = error("Not implemented")

is_self_loop(e::AbstractEdge) = src(e) == dst(e)
is_self_loop(e::Pair) = first(e) == last(e)

directed_graph_type(::Type{<:AbstractGraph}) = not_implemented()
undirected_graph_type(::Type{<:AbstractGraph}) = not_implemented()
# TODO: Implement generic version for `IsDirected`
# directed_graph_type(G::Type{IsDirected}) = G

directed_graph_type(g::AbstractGraph) = directed_graph_type(typeof(g))
undirected_graph_type(g::AbstractGraph) = undirected_graph_type(typeof(g))

@traitfn directed_graph(graph::::IsDirected) = graph

convert_vertextype(::Type{V}, G::AbstractGraph{V}) where {V} = G
convert_vertextype(::Type, ::AbstractGraph) = not_implemented()

convert_vertextype(::Type{V}, G::Type{<:AbstractGraph{V}}) where {V} = G
convert_vertextype(::Type, ::Type{<:AbstractGraph}) = not_implemented()

similar_graph(graph::AbstractGraph) = similar_graph(typeof(graph))
similar_graph(T::Type{<:AbstractGraph}) = T()

function similar_graph(graph_or_type, vertices)
    new_graph = similar_graph(graph_or_type, eltype(vertices))
    add_vertices!(new_graph, vertices)
    return new_graph
end
function similar_graph(graph_or_type, vertices, edges)
    new_graph = similar_graph(graph_or_type, vertices)
    add_edges!(new_graph, edges)
    return new_graph
end

function similar_graph(graph_or_type, vertex_type::Type)
    new_graph = convert_vertextype(vertex_type, similar_graph(graph_or_type))
    return new_graph
end

# TODO: Handle metadata in a generic way
@traitfn function directed_graph(graph::::(!IsDirected))
    digraph = similar_graph(directed_graph_type(graph), vertices(graph))
    for e in edges(graph)
        add_edge!(digraph, e)
        add_edge!(digraph, reverse(e))
    end
    return digraph
end

@traitfn undirected_graph(graph::::(!IsDirected)) = graph

# TODO: Handle metadata in a generic way
# Must have the same argument name as:
# @traitfn undirected_graph(graph::::(!IsDirected))
# to avoid method overwrite warnings, see:
# https://github.com/mauro3/SimpleTraits.jl#method-overwritten-warnings
@traitfn function undirected_graph(graph::::IsDirected)
    undigraph = similar_graph(undirected_graph_type(typeof(graph)), vertices(graph))
    for e in edges(graph)
        # TODO: Check for repeated edges?
        add_edge!(undigraph, e)
    end
    return undigraph
end

# Similar to `eltype`, but `eltype` doesn't work on types
vertextype(::Type{<:AbstractGraph{V}}) where {V} = V
vertextype(graph::AbstractGraph) = vertextype(typeof(graph))

vertextype(edge::AbstractEdge) = vertextype(typeof(edge))
vertextype(::Type{<:AbstractEdge{V}}) where {V} = V

function has_vertices(graph::AbstractGraph, vertices)
    return all(v -> has_vertex(graph, v), vertices)
end

function has_edges(graph::AbstractGraph, edges)
    return all(e -> has_edge(graph, e), edges)
end

# Uniform interface for `outneighbors`, `inneighbors`, and `all_neighbors`
function _neighbors(graph::AbstractGraph, vertex; dir = :out)
    if dir == :out
        return outneighbors(graph, vertex)
    elseif dir == :in
        return inneighbors(graph, vertex)
    elseif dir == :both
        return all_neighbors(graph, vertex)
    end
    return error(
        "`_neighbors(graph::AbstractGraph, vertex; dir)` with `dir = $(dir) not implemented. Use either `dir = :out`, `dir = :in`, or `dir = :both`.",
    )
end

# Returns just the edges of a directed graph,
# but both edge directions of an undirected graph.
# TODO: Move to NamedGraphs.jl
@traitfn function all_edges(g::::IsDirected)
    return edges(g)
end

@traitfn function all_edges(g::::(!IsDirected))
    e = edges(g)
    return Iterators.flatten(zip(e, reverse.(e)))
end

# Alternative syntax to `getindex` for getting a subgraph
# TODO: Should this preserve vertex names by
# converting to `NamedGraph` if indexed by
# something besides `Base.OneTo`?
function subgraph(graph::AbstractGraph, vertices)
    return induced_subgraph(graph, vertices)[1]
end

# TODO: Should this preserve vertex names by
# converting to `NamedGraph`?
function subgraph(f::Function, graph::AbstractGraph)
    return subgraph(graph, filter(f, vertices(graph)))
end

function edge_subgraph(graph::AbstractGraph, es::Vector{<:AbstractEdge})
    vs = unique(vcat(src.(es), dst.(es)))
    g = subgraph(graph, vs)
    g = rem_edges(g, edges(g))
    return add_edges(g, es)
end

function degrees(graph::AbstractGraph, vertices = vertices(graph))
    return map(vertex -> degree(graph, vertex), vertices)
end

function indegrees(graph::AbstractGraph, vertices = vertices(graph))
    return map(vertex -> indegree(graph, vertex), vertices)
end

function outdegrees(graph::AbstractGraph, vertices = vertices(graph))
    return map(vertex -> outdegree(graph, vertex), vertices)
end

# `Graphs.is_tree` only works on undirected graphs.
# TODO: Raise an issue.
@traitfn function is_ditree(graph::AbstractGraph::IsDirected)
    # For directed graphs, `is_connected(graph)` returns `true`
    # if `graph` is weakly connected.
    return is_connected(graph) && ne(graph) == nv(graph) - 1
end

# TODO: Define in `Graphs.jl`.
# https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.tree.recognition.is_tree.html
# https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.tree.recognition.is_arborescence.html
# https://networkx.org/documentation/stable/_modules/networkx/algorithms/tree/recognition.html#is_arborescence
# https://networkx.org/documentation/stable/_modules/networkx/algorithms/tree/recognition.html#is_tree
# https://en.wikipedia.org/wiki/Arborescence_(graph_theory)
# directed rooted tree
@traitfn function is_arborescence(graph::AbstractGraph::IsDirected)
    return is_ditree(graph) && all(v -> indegree(graph, v) ≤ 1, vertices(graph))
end

#
# Graph unions
#

# Function `f` maps original vertices `vᵢ` of `g`
# to new vertices `f(vᵢ)` of the output graph.
rename_vertices(f, g::AbstractGraph) = not_implemented()

# TODO: Does this relabel the vertices and/or change the adjacency matrix?
function permute_vertices(graph::AbstractGraph, permutation)
    return not_implemented()
end

# https://en.wikipedia.org/wiki/Disjoint_union
# Input maps the new index being appended to the vertices
# to the associated graph.
function disjoint_union(graphs::Dictionary{<:Any, <:AbstractGraph})
    return reduce(union, (rename_vertices(v -> (v, i), graphs[i]) for i in keys(graphs)))
end

function disjoint_union(graphs::Vector{<:AbstractGraph})
    return disjoint_union(Dictionary(graphs))
end

disjoint_union(graph::AbstractGraph) = graph

function disjoint_union(graph1::AbstractGraph, graphs_tail::AbstractGraph...)
    return disjoint_union(Dictionary([graph1, graphs_tail...]))
end

function disjoint_union(pairs::Pair...)
    return disjoint_union([pairs...])
end

function disjoint_union(iter::Vector{<:Pair})
    return disjoint_union(dictionary(iter))
end

function ⊔(graphs...; kwargs...)
    return disjoint_union(graphs...; kwargs...)
end

"""
Check if an undirected graph is a path/linear graph:

https://en.wikipedia.org/wiki/Path_graph

but not a path/linear forest:

https://en.wikipedia.org/wiki/Linear_forest
"""
@traitfn function is_path_graph(graph::::(!IsDirected))
    return is_tree(graph) && (Δ(graph) == 2)
end

"""
https://juliagraphs.org/Graphs.jl/dev/core_functions/simplegraphs_generators/#Graphs.SimpleGraphs.cycle_graph-Tuple%7BT%7D%20where%20T%3C:Integer
https://en.wikipedia.org/wiki/Cycle_graph
"""
@traitfn function is_cycle_graph(graph::::(!IsDirected))
    return all(==(2), degrees(graph))
end

function out_incident_edges(graph::AbstractGraph, vertex)
    return [
        edgetype(graph)(vertex, neighbor_vertex) for
            neighbor_vertex in outneighbors(graph, vertex)
    ]
end

function in_incident_edges(graph::AbstractGraph, vertex)
    return [
        edgetype(graph)(neighbor_vertex, vertex) for
            neighbor_vertex in inneighbors(graph, vertex)
    ]
end

# TODO: Only return one set of `:out` edges for undirected graphs if `dir=:both`.
function all_incident_edges(graph::AbstractGraph, vertex)
    return out_incident_edges(graph, vertex) ∪ in_incident_edges(graph, vertex)
end

# TODO: Same as `edges(subgraph(graph, [vertex; neighbors(graph, vertex)]))`.
# TODO: Only return one set of `:out` edges for undirected graphs if `dir=:both`.
"""
    incident_edges(graph::AbstractGraph, vertex; dir=:out)

Edges incident to the vertex `vertex`.

`dir ∈ (:in, :out, :both)`, defaults to `:out`.

For undirected graphs, returns all incident edges.

Like: https://juliagraphs.org/Graphs.jl/v1.7/algorithms/linalg/#Graphs.LinAlg.adjacency_matrix
"""
function incident_edges(graph::AbstractGraph, vertex; dir = :out)
    if dir == :out
        return out_incident_edges(graph, vertex)
    elseif dir == :in
        return in_incident_edges(graph, vertex)
    elseif dir == :both
        return all_incident_edges(graph, vertex)
    end
    return error("dir = $dir not supported.")
end

# Get the leaf vertices of a tree-like graph
#
# For the directed case, could also use `AbstractTrees`:
#
# root_index = findfirst(vertex -> length(outneighbors(vertex)) == length(neighbors(vertex)), vertices(graph))
# root = vertices(graph)[root_index]
# map(nodevalue, Leaves(tree_graph_node(graph, root)))
#
@traitfn function is_leaf_vertex(graph::::(!IsDirected), vertex)
    # @assert !is_cyclic(graph)
    return isone(length(neighbors(graph, vertex)))
end

# Check if a vertex is a leaf.
# Assumes the graph is a DAG.
@traitfn function is_leaf_vertex(graph::::IsDirected, vertex)
    # @assert !is_cyclic(graph)
    return isempty(child_vertices(graph, vertex))
end

# Get the children of a vertex.
# Assumes the graph is a DAG.
@traitfn function child_vertices(graph::::IsDirected, vertex)
    # @assert !is_cyclic(graph)
    return outneighbors(graph, vertex)
end

# Get the edges from the input vertex towards the child vertices.
# Assumes the graph is a DAG.
@traitfn function child_edges(graph::::IsDirected, vertex)
    # @assert !is_cyclic(graph)
    return map(child -> edgetype(graph)(vertex, child), child_vertices(graph, vertex))
end

function leaf_vertices(graph::AbstractGraph)
    # @assert !is_cyclic(graph)
    return filter(v -> is_leaf_vertex(graph, v), vertices(graph))
end

"""
Determine if an edge involves a leaf (at src or dst)
"""
@traitfn function is_leaf_edge(g::::(!IsDirected), e::AbstractEdge)
    return has_edge(g, e) && (is_leaf_vertex(g, src(e)) || is_leaf_vertex(g, dst(e)))
end
@traitfn function is_leaf_edge(g::::IsDirected, e::AbstractEdge)
    return has_edge(g, e) && is_leaf_vertex(g, dst(e))
end
function is_leaf_edge(g::AbstractGraph, e::Pair)
    return is_leaf_edge(g, edgetype(g)(e))
end

"""
Determine if a node has any neighbors which are leaves
"""
function has_leaf_neighbor(g::AbstractGraph, v)
    return any(w -> is_leaf_vertex(g, w), neighbors(g, v))
end

"""
Get all edges which do not involve a leaf

https://en.wikipedia.org/wiki/Tree_(graph_theory)#Definitions
"""
function non_leaf_edges(g::AbstractGraph)
    return Iterators.filter(e -> !is_leaf_edge(g, e), edges(g))
end

"""
Get distance of a vertex from a leaf
"""
function distance_to_leaves(g::AbstractGraph, v)
    return map(Indices(leaf_vertices(g))) do leaf
        v == leaf && return 0
        path = a_star(g, v, leaf)
        isempty(path) && return typemax(Int)
        return length(path)
    end
end

function minimum_distance_to_leaves(g::AbstractGraph, v)
    return minimum(distance_to_leaves(g, v))
end

@traitfn function is_root_vertex(graph::::IsDirected, vertex)
    return isempty(parent_vertices(graph, vertex))
end

@traitfn function is_rooted(graph::::IsDirected)
    return isone(count(v -> is_root_vertex(graph, v), vertices(graph)))
end

@traitfn function is_binary_arborescence(graph::AbstractGraph::IsDirected)
    (is_rooted(graph) && is_arborescence(graph)) || return false
    for v in vertices(graph)
        if length(child_vertices(graph, v)) > 2
            return false
        end
    end
    return true
end

"""
Return the root vertex of a rooted directed graph.

This will return the first root vertex that is found,
so won't error if there is more than one.
"""
@traitfn function root_vertex(graph::::IsDirected)
    if is_cyclic(graph)
        return error("Graph must not have any cycles.")
    end
    v = first(vertices(graph))
    while !is_root_vertex(graph, v)
        v = parent_vertex(graph, v)
    end
    return v
end

#
# Graph iteration
#

@traitfn function post_order_dfs_vertices(graph::::(!IsDirected), root_vertex)
    dfs_tree_graph = dfs_tree(graph, root_vertex)
    return post_order_dfs_vertices(dfs_tree_graph, root_vertex)
end

# Traverse the tree using a [post-order depth-first search](https://en.wikipedia.org/wiki/Tree_traversal#Depth-first_search), returning the vertices.
# Assumes the graph is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree)
@traitfn function post_order_dfs_vertices(graph::::IsDirected, root_vertex)
    # @assert is_tree(graph)
    # Outputs a rooted directed tree (https://en.wikipedia.org/wiki/Arborescence_(graph_theory))
    return map(nodevalue, PostOrderDFS(tree_graph_node(graph, root_vertex)))
end

@traitfn function pre_order_dfs_vertices(graph::::(!IsDirected), root_vertex)
    dfs_tree_graph = dfs_tree(graph, root_vertex)
    return pre_order_dfs_vertices(dfs_tree_graph, root_vertex)
end

@traitfn function pre_order_dfs_vertices(graph::::IsDirected, root_vertex)
    # @assert is_tree(graph)
    return map(nodevalue, PreOrderDFS(tree_graph_node(graph, root_vertex)))
end

@traitfn function post_order_dfs_edges(graph::::(!IsDirected), root_vertex)
    dfs_tree_graph = dfs_tree(graph, root_vertex)
    return post_order_dfs_edges(dfs_tree_graph, root_vertex)
end

# Traverse the tree using a [post-order depth-first search](https://en.wikipedia.org/wiki/Tree_traversal#Depth-first_search), returning the edges where the source is the current vertex and the destination is the parent vertex.
# Assumes the graph is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree).
# Returns a list of edges directed **towards the root vertex**!
@traitfn function post_order_dfs_edges(graph::::IsDirected, root_vertex)
    # @assert is_tree(graph)
    vertices = post_order_dfs_vertices(graph, root_vertex)
    # Remove the root vertex
    pop!(vertices)
    return map(vertex -> parent_edge(graph, vertex), vertices)
end

# Paths for undirected tree-like graphs
# TODO: Use `a_star`.
@traitfn function vertex_path(graph::::(!IsDirected), s, t)
    # @assert is_tree(graph)
    dfs_tree_graph = dfs_tree(graph, t)
    return vertex_path(dfs_tree_graph, s, t)
end

# TODO: Use `a_star`.
@traitfn function edge_path(graph::::(!IsDirected), s, t)
    # @assert is_tree(graph)
    dfs_tree_graph = dfs_tree(graph, t)
    return edge_path(dfs_tree_graph, s, t)
end

#
# Rooted directed tree/directed acyclic graph functions.
# [Rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree)
# [Directed acyclic graph (DAG)](https://en.wikipedia.org/wiki/Directed_acyclic_graph)
#

# Get the parent vertices of a vertex.
# Assumes the graph is a DAG.
@traitfn function parent_vertices(graph::::IsDirected, vertex)
    # @assert !is_cyclic(graph)
    return inneighbors(graph, vertex)
end

# Get the parent vertex of a vertex.
# Assumes the graph is a DAG.
@traitfn function parent_vertex(graph::::IsDirected, vertex)
    # @assert !is_cyclic(graph)
    parents = parent_vertices(graph, vertex)
    return isempty(parents) ? nothing : only(parents)
end

# Returns the edges directed **towards the parent vertices**!
# Assumes the graph is a DAG.
@traitfn function parent_edges(graph::::IsDirected, vertex)
    # @assert !is_cyclic(graph)
    return map(parent -> edgetype(graph)(vertex, parent), parent_vertices(graph, vertex))
end

# Returns the edge directed **towards the parent vertex**!
# Assumes the graph is a DAG.
@traitfn function parent_edge(graph::::IsDirected, vertex)
    parents = parent_edges(graph, vertex)
    return isempty(parents) ? nothing : only(parents)
end

# Paths for directed tree-like graphs
# TODO: Use `a_star`, make specialized versions:
# `vertex_path(graph::::IsTree, ...)`
# or
# `tree_vertex_path(graph, ...)`
@traitfn function vertex_path(graph::::IsDirected, s, t)
    # @assert is_tree(graph)
    vertices = eltype(graph)[s]
    while vertices[end] != t
        parent = parent_vertex(graph, vertices[end])
        isnothing(parent) && return nothing
        push!(vertices, parent)
    end
    return vertices
end

# TODO: Use `a_star`, make specialized versions:
# `vertex_path(graph::::IsTree, ...)`
# or
# `tree_vertex_path(graph, ...)`
@traitfn function edge_path(graph::::IsDirected, s, t)
    # @assert is_tree(graph)
    vertices = vertex_path(graph, s, t)
    isnothing(vertices) && return nothing
    pop!(vertices)
    return [edgetype(graph)(vertex, parent_vertex(graph, vertex)) for vertex in vertices]
end

function mincut_partitions(graph::AbstractGraph, distmx = weights(graph))
    parts = groupfind(first(Graphs.mincut(graph, distmx)))
    return parts[1], parts[2]
end

function add_vertex(g::AbstractGraph, vs)
    g = copy(g)
    add_vertex!(g, vs)
    return g
end

function add_vertices!(graph::AbstractGraph, vs)
    for vertex in vs
        add_vertex!(graph, vertex)
    end
    return graph
end

function add_vertices(g::AbstractGraph, vs)
    g = copy(g)
    add_vertices!(g, vs)
    return g
end

function rem_vertex(g::AbstractGraph, vs)
    g = copy(g)
    rem_vertex!(g, vs)
    return g
end

"""Remove a list of vertices from a graph g"""
function rem_vertices!(g::AbstractGraph, vs)
    for v in vs
        rem_vertex!(g, v)
    end
    return g
end

function rem_vertices(g::AbstractGraph, vs)
    g = copy(g)
    rem_vertices!(g, vs)
    return g
end

function add_edge(g::AbstractGraph, edge)
    g = copy(g)
    add_edge!(g, edgetype(g)(edge))
    return g
end

"""Add a list of edges to a graph g"""
function add_edges!(g::AbstractGraph, edges)
    for e in edges
        add_edge!(g, edgetype(g)(e))
    end
    return g
end

function add_edges(g::AbstractGraph, edges)
    g = copy(g)
    add_edges!(g, edges)
    return g
end

function rem_edge(g::AbstractGraph, edge)
    g = copy(g)
    rem_edge!(g, edgetype(g)(edge))
    return g
end

"""Remove a list of edges from a graph g"""
function rem_edges!(g::AbstractGraph, edges)
    for e in edges
        rem_edge!(g, edgetype(g)(e))
    end
    return g
end

function rem_edges(g::AbstractGraph, edges)
    g = copy(g)
    rem_edges!(g, edges)
    return g
end

eccentricities(graph::AbstractGraph) = eccentricities(graph, vertices(graph))

function eccentricities(graph::AbstractGraph, vs, distmx = weights(graph))
    return map(vertex -> eccentricity(graph, vertex, distmx), vs)
end

function decorate_graph_edges(g::AbstractGraph; kwargs...)
    return not_implemented()
end

function decorate_graph_vertices(g::AbstractGraph; kwargs...)
    return not_implemented()
end

""" Do a BFS search to construct a tree, but do it with randomness to avoid generating the same tree. Based on Int. J. Comput. Their Appl. 15 pp 177-186 (2008). Edges will point away from source vertex s."""
function random_bfs_tree(g::AbstractGraph, s; maxiter = 1000 * (nv(g) + ne(g)))
    Q = [s]
    d = map(v -> v == s ? 0.0 : Inf, Indices(vertices(g)))
    visited = [s]

    # TODO: This fails for `SimpleDiGraph`.
    g_out = directed_graph_type(g)(vertices(g))

    isempty_Q = false
    for iter in 1:maxiter
        v = rand(Q)
        setdiff!(Q, [v])
        for vn in neighbors(g, v)
            if (d[vn] > d[v] + 1)
                d[vn] = d[v] + 1
                if (vn ∉ Q)
                    if (vn ∉ visited)
                        add_edge!(g_out, edgetype(g)(v, vn))
                        push!(visited, vn)
                    end
                    push!(Q, vn)
                end
            end
        end
        isempty_Q = isempty(Q)
        if isempty_Q
            break
        end
    end
    if !isempty_Q
        error("Search failed to cover the graph in time. Consider increasing maxiter.")
    end
    return g_out
end
