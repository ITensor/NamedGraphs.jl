module NamedGraphs
include("lib/SimilarType/src/SimilarType.jl")
include("lib/Keys/src/Keys.jl")
include("lib/OrdinalIndexing/src/OrdinalIndexing.jl")
include("lib/OrderedDictionaries/src/OrderedDictionaries.jl")
include("lib/GraphGenerators/src/GraphGenerators.jl")
include("lib/GraphsExtensions/src/GraphsExtensions.jl")
include("utils.jl")
include("abstractnamededge.jl")
include("namededge.jl")
include("abstractnamedgraph.jl")
include("decorate.jl")
include("simplecycles.jl")
include("shortestpaths.jl")
include("distance.jl")
include("distances_and_capacities.jl")
include("steiner_tree.jl")
include("dfs.jl")
include("namedgraph.jl")
include("positiongraphview.jl")
include("lib/NamedGraphGenerators/src/NamedGraphGenerators.jl")
include("lib/PartitionedGraphs/src/PartitionedGraphs.jl")

export AbstractNamedGraph, NamedDiGraph, NamedEdge, NamedGraph

using PackageExtensionCompat: @require_extensions
function __init__()
    return @require_extensions
end
end
