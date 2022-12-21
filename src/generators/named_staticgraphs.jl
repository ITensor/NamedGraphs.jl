function parent(tree::SimpleDiGraph, v::Integer)
  return only(inneighbors(tree, v))
end

function children(tree::SimpleDiGraph, v::Integer)
  return outneighbors(tree, v)
end

function set_named_vertices!(
  named_vertices::Vector,
  tree::SimpleDiGraph,
  simple_parent::Integer,
  named_parent;
  child_name=identity,
)
  simple_children = children(tree, simple_parent)
  for n in 1:length(simple_children)
    simple_child = simple_children[n]
    named_child = (named_parent..., child_name(n))
    named_vertices[simple_child] = named_child
    set_named_vertices!(named_vertices, tree, simple_child, named_child; child_name)
  end
  return named_vertices
end

# TODO: Use vectors as vertex names?
# k = 3:
# 1 => (1,)
# 2 => (1, 1)
# 3 => (1, 2)
# 4 => (1, 1, 1)
# 5 => (1, 1, 2)
# 6 => (1, 2, 1)
# 7 => (1, 2, 2)
function named_bfs_tree_vertices(
  simple_graph::SimpleGraph, source::Integer=1; source_name=1, child_name=identity
)
  tree = bfs_tree(simple_graph, source)
  named_vertices = Vector{Tuple}(undef, nv(simple_graph))
  named_source = (source_name,)
  named_vertices[source] = named_source
  set_named_vertices!(named_vertices, tree, source, named_source; child_name)
  return named_vertices
end

function named_bfs_tree(
  simple_graph::SimpleGraph, source::Integer=1; source_name=1, child_name=identity
)
  named_vertices = named_bfs_tree_vertices(simple_graph, source; source_name, child_name)
  return NamedGraph(simple_graph; vertices=named_vertices)
end

function named_binary_tree(
  k::Integer, source::Integer=1; source_name=1, child_name=identity
)
  simple_graph = binary_tree(k)
  return named_bfs_tree(simple_graph, source; source_name, child_name)
end

function named_path_graph(dim::Integer)
  return NamedGraph(path_graph(dim))
end

function named_path_digraph(dim::Integer)
  return NamedDiGraph(path_digraph(dim))
end

function named_grid(dim::Integer; kwargs...)
  simple_graph = grid((dim,); kwargs...)
  return NamedGraph(simple_graph)
end

function named_grid(dims; kwargs...)
  simple_graph = grid(dims; kwargs...)
  return NamedGraph(simple_graph; vertices=dims)
end

function named_comb_tree(dims::Tuple)
  simple_graph = comb_tree(dims)
  return NamedGraph(simple_graph; vertices=dims)
end

function named_comb_tree(tooth_lengths::Vector{<:Integer})
  @assert all(>(0), tooth_lengths)
  simple_graph = comb_tree(tooth_lengths)
  nx = length(tooth_lengths)
  ny = maximum(tooth_lengths)
  vertices = filter(Tuple.(CartesianIndices((nx, ny)))) do (jx, jy)
    jy <= tooth_lengths[jx]
  end
  return NamedGraph(simple_graph; vertices)
end
