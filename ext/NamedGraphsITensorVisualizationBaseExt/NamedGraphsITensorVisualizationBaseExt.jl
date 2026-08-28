module NamedGraphsITensorVisualizationBaseExt

using Graphs: vertices
using ITensorVisualizationBase: ITensorVisualizationBase
using NamedGraphs: AbstractNamedGraph, decoded_vertex, encoded_graph

function ITensorVisualizationBase.visualize(
        graph::AbstractNamedGraph,
        args...;
        vertex_labels_prefix = nothing,
        vertex_labels = nothing,
        kwargs...
    )
    if !isnothing(vertex_labels_prefix)
        # In code order, to align with the vertices of `encoded_graph(graph)`.
        vertex_labels = [
            vertex_labels_prefix * string(decoded_vertex(graph, c)) for
                c in vertices(encoded_graph(graph))
        ]
    end
    return ITensorVisualizationBase.visualize(
        encoded_graph(graph), args...; vertex_labels, kwargs...
    )
end

end
