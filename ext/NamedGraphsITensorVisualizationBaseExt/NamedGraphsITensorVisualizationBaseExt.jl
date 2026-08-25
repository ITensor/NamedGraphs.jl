module NamedGraphsITensorVisualizationBaseExt

using Graphs: vertices
using ITensorVisualizationBase: ITensorVisualizationBase
using NamedGraphs: AbstractNamedGraph, coded_graph, decoded_vertices

function ITensorVisualizationBase.visualize(
        graph::AbstractNamedGraph,
        args...;
        vertex_labels_prefix = nothing,
        vertex_labels = nothing,
        kwargs...
    )
    if !isnothing(vertex_labels_prefix)
        # In code order, to align with the vertices of `coded_graph(graph)`.
        vertex_labels = [
            vertex_labels_prefix * string(v) for v in decoded_vertices(graph)
        ]
    end
    return ITensorVisualizationBase.visualize(
        coded_graph(graph), args...; vertex_labels, kwargs...
    )
end

end
