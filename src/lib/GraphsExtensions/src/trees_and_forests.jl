using Graphs: IsDirected, bfs_tree, connected_components, edges, edgetype
using .GraphsExtensions: random_bfs_tree, rem_edges, undirected_graph
using SimpleTraits: SimpleTraits, Not, @traitfn

abstract type SpanningTreeAlgorithm end

struct BFS <: SpanningTreeAlgorithm end
struct RandomBFS <: SpanningTreeAlgorithm end
struct DFS <: SpanningTreeAlgorithm end

default_spanning_tree_alg() = BFS()

default_root_vertex(g) = last(findmax(eccentricities(g)))

function spanning_tree(
  g::AbstractGraph; alg=default_spanning_tree_alg(), root_vertex=default_root_vertex(g)
)
  return spanning_tree(alg, g; root_vertex)
end

@traitfn function spanning_tree(
  ::BFS, g::AbstractGraph::(!IsDirected); root_vertex=default_root_vertex(g)
)
  return undirected_graph(bfs_tree(g, root_vertex))
end

@traitfn function spanning_tree(
  ::RandomBFS, g::AbstractGraph::(!IsDirected); root_vertex=default_root_vertex(g)
)
  return undirected_graph(random_bfs_tree(g, root_vertex))
end

@traitfn function spanning_tree(
  ::DFS, g::AbstractGraph::(!IsDirected); root_vertex=default_root_vertex(g)
)
  return undirected_graph(dfs_tree(g, root_vertex))
end

# Given a graph, split it into its connected components, construct a spanning tree, using the function spanning_tree, over each of them
# and take the union.
function spanning_forest(g::AbstractGraph; spanning_tree=spanning_tree)
  return reduce(union, (spanning_tree(subgraph(g, vs)) for vs in connected_components(g)))
end

# TODO: Create a generic version in `GraphsExtensions`.
# Given an undirected graph g with vertex set V, build a set of forests (each with vertex set V) which covers all edges in g
# (see https://en.wikipedia.org/wiki/Arboricity) We do not find the minimum but our tests show this algorithm performs well
function forest_cover(g::AbstractGraph; spanning_tree=spanning_tree)
  edges_collected = edgetype(g)[]
  remaining_edges = edges(g)
  forests = typeof(g)[]
  while !isempty(remaining_edges)
    g_reduced = rem_edges(g, edges_collected)
    g_reduced_spanning_forest = spanning_forest(g_reduced; spanning_tree)
    push!(edges_collected, edges(g_reduced_spanning_forest)...)
    push!(forests, g_reduced_spanning_forest)
    setdiff!(remaining_edges, edges(g_reduced_spanning_forest))
  end
  return forests
end

# TODO: Define in `NamedGraphs.PartitionedGraphs`.
# forest_cover(g::PartitionedGraph; kwargs...) = not_implemented()
