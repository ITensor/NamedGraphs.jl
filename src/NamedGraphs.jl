module NamedGraphs
include("similartype.jl")
include("GraphsExtensions/GraphsExtensions.jl")
include("utils.jl")
include("abstractnamededge.jl")
include("namededge.jl")
include("abstractnamedgraph.jl")
include("indicesviews.jl")
include("abstractgraphindices.jl")
include("similar_graph.jl")
include("decorate.jl")
include("shortestpaths.jl")
include("distance.jl")
include("distances_and_capacities.jl")
include("steiner_tree.jl")
include("dfs.jl")
include("namedgraph.jl")
include("encodedgraphview.jl")
include("simplecycles.jl")
include("namedgraphgenerators.jl")
include("namedgridgraph.jl")
include("PartitionedGraphs/PartitionedGraphs.jl")

export AbstractNamedGraph, NamedDiGraph, NamedEdge, NamedGraph

using PackageExtensionCompat: @require_extensions
function __init__()
    return @require_extensions
end
end
