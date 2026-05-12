module NamedGraphsITensorVisualizationBaseExt

using Graphs: vertices
using ITensorVisualizationBase: ITensorVisualizationBase
using NamedGraphs: AbstractNamedGraph, position_graph

function ITensorVisualizationBase.visualize(
        graph::AbstractNamedGraph,
        args...;
        vertex_labels_prefix = nothing,
        vertex_labels = nothing,
        kwargs...
    )
    if !isnothing(vertex_labels_prefix)
        vertex_labels = [vertex_labels_prefix * string(v) for v in vertices(graph)]
    end
    return ITensorVisualizationBase.visualize(
        position_graph(graph), args...; vertex_labels, kwargs...
    )
end

end
