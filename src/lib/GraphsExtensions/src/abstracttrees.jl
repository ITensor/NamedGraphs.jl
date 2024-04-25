# AbstractTreeGraph
# Tree view of a graph.
abstract type AbstractTreeGraph{V} <: AbstractGraph{V} end
one_based_graph_type(type::Type{<:AbstractTreeGraph}) = not_implemented()
one_based_graph(graph::AbstractTreeGraph) = not_implemented()

function Graphs.is_directed(type::Type{<:AbstractTreeGraph})
  return is_directed(one_based_graph_type(type))
end
Graphs.edgetype(graph::AbstractTreeGraph) = edgetype(one_based_graph(graph))
function Graphs.outneighbors(graph::AbstractTreeGraph, vertex)
  return outneighbors(one_based_graph(graph), vertex)
end
function Graphs.inneighbors(graph::AbstractTreeGraph, vertex)
  return inneighbors(one_based_graph(graph), vertex)
end
Graphs.nv(graph::AbstractTreeGraph) = nv(one_based_graph(graph))
Graphs.ne(graph::AbstractTreeGraph) = ne(one_based_graph(graph))
Graphs.vertices(graph::AbstractTreeGraph) = vertices(one_based_graph(graph))

# AbstractTrees
using AbstractTrees:
  AbstractTrees, IndexNode, PostOrderDFS, PreOrderDFS, children, nodevalue

# Used for tree iteration.
# Assumes the graph is a [rooted directed tree](https://en.wikipedia.org/wiki/Tree_(graph_theory)#Rooted_tree).
tree_graph_node(g::AbstractTreeGraph, vertex) = IndexNode(g, vertex)
function tree_graph_node(g::AbstractGraph, vertex)
  return tree_graph_node(TreeGraph(g), vertex)
end
tree_graph_node(g::AbstractGraph) = tree_graph_node(g, root_vertex(g))

# Make an `AbstractTreeGraph` act as an `AbstractTree` starting at
# the root vertex.
AbstractTrees.children(g::AbstractTreeGraph) = children(tree_graph_node(g))
AbstractTrees.nodevalue(g::AbstractTreeGraph) = nodevalue(tree_graph_node(g))

AbstractTrees.rootindex(tree::AbstractTreeGraph) = root_vertex(tree)
function AbstractTrees.nodevalue(tree::AbstractTreeGraph, node_index)
  return node_index
end
function AbstractTrees.childindices(tree::AbstractTreeGraph, node_index)
  return child_vertices(tree, node_index)
end
function AbstractTrees.parentindex(tree::AbstractTreeGraph, node_index)
  return parent_vertex(tree, node_index)
end

# TreeGraph
struct TreeGraph{V,G<:AbstractGraph{V}} <: AbstractTreeGraph{V}
  graph::G
  global function _TreeGraph(g::AbstractGraph)
    # No check for being a tree
    return new{vertextype(g),typeof(g)}(g)
  end
end
@traitfn function TreeGraph(g::AbstractGraph::IsDirected)
  @assert is_arborescence(g)
  return _TreeGraph(g)
end
@traitfn function TreeGraph(g::AbstractGraph::(!IsDirected))
  @assert is_tree(g)
  return _TreeGraph(g)
end
one_based_graph(graph::TreeGraph) = getfield(graph, :graph)
one_based_graph_type(type::Type{<:TreeGraph}) = fieldtype(type, :graph)
