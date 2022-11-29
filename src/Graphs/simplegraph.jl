########################################################################
# Graphs.SimpleGraphs extensions

# TODO: Move to `SimpleGraph` file
# TODO: Use trait dispatch to do no-ops when appropriate
directed_graph(G::Type{<:SimpleGraph}) = SimpleDiGraph{vertextype(G)}
undirected_graph(G::Type{<:SimpleGraph}) = G
directed_graph(G::Type{<:SimpleDiGraph}) = G
undirected_graph(G::Type{<:SimpleDiGraph}) = SimpleGraph{vertextype(G)}

function set_vertices(graph::AbstractSimpleGraph, vertices::Vector)
  return GenericNamedGraph(graph, vertices)
end
