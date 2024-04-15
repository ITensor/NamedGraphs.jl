using Graphs.SimpleGraphs: SimpleDiGraph, SimpleGraph

########################################################################
# Graphs.SimpleGraphs extensions

# TODO: Move to `SimpleGraph` file
# TODO: Use trait dispatch to do no-ops when appropriate
directed_graph_type(G::Type{<:SimpleGraph}) = SimpleDiGraph{vertextype(G)}
undirected_graph_type(G::Type{<:SimpleGraph}) = G
directed_graph_type(G::Type{<:SimpleDiGraph}) = G
undirected_graph_type(G::Type{<:SimpleDiGraph}) = SimpleGraph{vertextype(G)}
