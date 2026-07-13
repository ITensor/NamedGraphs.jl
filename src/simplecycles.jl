using Graphs: AbstractGraph, edges, dst, src, vertices
using .GraphsExtensions: GraphsExtensions, edge_subgraph

# Enumeration of connected edge-induced subgraphs with no leaf vertices (the "generalized
# loops" of a loop / linked-cluster expansion).
#
# The algorithm is ESU (Wernicke, "A faster algorithm for detecting network motifs",
# WABI 2006) run on the line graph of `g`: a connected edge set of `g` is a connected vertex
# set of the line graph, and ESU visits each connected vertex set EXACTLY ONCE using the rule
# "the smallest-index edge is the root, and the set only grows via strictly-larger exclusive
# neighbours". This avoids any deduplication hashing. Induced vertex degrees and the leaf
# count are tracked incrementally as edges are added and removed.

# Mutable state carried through the recursion. The topology fields are fixed for a given
# graph; the remaining fields describe the edge set currently being built.
mutable struct NoLeafSubgraphSearch
    # Endpoints of each edge, as integer vertex indices (indexed by edge index).
    const edge_src::Vector{Int}
    const edge_dst::Vector{Int}
    # Line-graph adjacency: `edge_neighbours[i]` lists the edges sharing a vertex with edge `i`.
    const edge_neighbours::Vector{Vector{Int}}
    const max_edges::Int
    # Induced degree of each vertex within the current edge set.
    const vertex_degree::Vector{Int}
    # Number of vertices whose induced degree is exactly 1 (i.e. leaves of the current set).
    num_leaves::Int
    # `marked[u]` is true while edge `u` is in the current set or already queued for it.
    const marked::Vector{Bool}
    # The current edge set, used as a stack.
    const current_edges::Vector{Int}
    # Completed leaf-free edge sets (each a vector of edge indices).
    const results::Vector{Vector{Int}}
end

# Add edge `i` to the current set, updating induced degrees and the leaf count.
@inline function apply_edge!(search::NoLeafSubgraphSearch, i)
    @inbounds for v in (search.edge_src[i], search.edge_dst[i])
        degree = search.vertex_degree[v]
        search.vertex_degree[v] = degree + 1
        if degree == 0        # vertex just became a leaf
            search.num_leaves += 1
        elseif degree == 1    # vertex is no longer a leaf
            search.num_leaves -= 1
        end
    end
    return search
end

# Inverse of `apply_edge!`: remove edge `i` from the current set.
@inline function revert_edge!(search::NoLeafSubgraphSearch, i)
    @inbounds for v in (search.edge_src[i], search.edge_dst[i])
        degree = search.vertex_degree[v]
        search.vertex_degree[v] = degree - 1
        if degree == 1        # vertex left the set entirely
            search.num_leaves -= 1
        elseif degree == 2    # vertex dropped back to being a leaf
            search.num_leaves += 1
        end
    end
    return search
end

# ESU recursion. `extension` holds the candidate edges that may be added next (all with index
# greater than `root`); `root` is the smallest edge index in the current set.
function extend_subgraph!(search::NoLeafSubgraphSearch, extension, root)
    # A non-empty set with no leaves is a valid generalized loop.
    if search.num_leaves == 0 && !isempty(search.current_edges)
        push!(search.results, copy(search.current_edges))
    end
    length(search.current_edges) >= search.max_edges && return search
    # Leaf prune: each added edge removes at most 2 leaves, so a set with more leaves than
    # twice the remaining edge budget can never become leaf-free in time.
    remaining_budget = search.max_edges - length(search.current_edges)
    search.num_leaves > 2 * remaining_budget && return search

    newly_marked = Int[]
    while !isempty(extension)
        w = pop!(extension)
        # Candidates for the recursive call: the remaining siblings plus the exclusive
        # neighbours of `w` (neighbours not already marked, with index greater than `root`).
        child_extension = copy(extension)
        empty!(newly_marked)
        @inbounds for u in search.edge_neighbours[w]
            if u > root && !search.marked[u]
                search.marked[u] = true
                push!(child_extension, u)
                push!(newly_marked, u)
            end
        end

        apply_edge!(search, w)
        push!(search.current_edges, w)
        extend_subgraph!(search, child_extension, root)
        pop!(search.current_edges)
        revert_edge!(search, w)

        # Unmark only the edges this `w` introduced; `w` itself stays marked so its siblings
        # do not re-queue it (the parent call unmarks `w`).
        @inbounds for u in newly_marked
            search.marked[u] = false
        end
    end
    return search
end

"""
    edgeinduced_subgraphs_no_leaves(g::AbstractGraph, max_edges::Integer) -> Vector

Enumerate all connected edge-induced subgraphs of `g` with at most `max_edges` edges in which
every vertex has induced degree `>= 2` (i.e. no leaf vertices) — the "generalized loops" used
in a loop / linked-cluster series.

Enumeration uses ESU on the line graph of `g`, so every connected edge set is visited exactly
once without deduplication, and induced degrees and the leaf count are maintained incrementally.
Returns a `Vector` of subgraphs of `g` (one per generalized loop).
"""
function edgeinduced_subgraphs_no_leaves(g::AbstractGraph, max_edges::Integer)
    edge_list = collect(edges(g))
    num_edges = length(edge_list)
    # The smallest possible leaf-free subgraph is a 3-cycle, so anything below 3 edges is empty.
    (num_edges == 0 || max_edges < 3) && return typeof(g)[]

    # Index vertices by integer for O(1) degree bookkeeping.
    vertex_list = collect(vertices(g))
    vertex_index = Dict{eltype(vertex_list), Int}()
    for (i, v) in enumerate(vertex_list)
        vertex_index[v] = i
    end

    edge_src = Vector{Int}(undef, num_edges)
    edge_dst = Vector{Int}(undef, num_edges)
    incident_edges = [Int[] for _ in vertex_list]   # edge indices touching each vertex
    for (i, e) in enumerate(edge_list)
        a = vertex_index[src(e)]
        b = vertex_index[dst(e)]
        edge_src[i] = a
        edge_dst[i] = b
        push!(incident_edges[a], i)
        push!(incident_edges[b], i)
    end

    # Line-graph adjacency: two edges are adjacent iff they share a vertex.
    edge_neighbours = [Int[] for _ in 1:num_edges]
    for edges_at_vertex in incident_edges, i in edges_at_vertex, j in edges_at_vertex
        i != j && push!(edge_neighbours[i], j)
    end
    for i in 1:num_edges
        unique!(edge_neighbours[i])
    end

    search = NoLeafSubgraphSearch(
        edge_src,
        edge_dst,
        edge_neighbours,
        max_edges,
        zeros(Int, length(vertex_list)),
        0,
        falses(num_edges),
        Int[],
        Vector{Int}[],
    )

    # Seed the search from each edge as a root, growing only towards larger edge indices so
    # that each connected edge set is generated exactly once (from its minimum edge).
    newly_marked = Int[]
    for root in 1:num_edges
        apply_edge!(search, root)
        push!(search.current_edges, root)
        search.marked[root] = true

        extension = Int[]
        empty!(newly_marked)
        @inbounds for u in edge_neighbours[root]
            if u > root && !search.marked[u]
                search.marked[u] = true
                push!(extension, u)
                push!(newly_marked, u)
            end
        end

        extend_subgraph!(search, extension, root)

        pop!(search.current_edges)
        revert_edge!(search, root)
        search.marked[root] = false
        @inbounds for u in newly_marked
            search.marked[u] = false
        end
    end

    return [edge_subgraph(g, edge_list[edge_set]) for edge_set in search.results]
end
