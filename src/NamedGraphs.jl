module NamedGraphs
include("lib/Keys/src/Keys.jl")
include("lib/GraphGenerators/src/GraphGenerators.jl")
include("lib/GraphsExtensions/src/GraphsExtensions.jl")
include("utils.jl")
include("abstractnamededge.jl")
include("namededge.jl")
include("abstractnamedgraph.jl")
include("decorate.jl")
include("shortestpaths.jl")
include("distance.jl")
include("distances_and_capacities.jl")
include("steiner_tree/steiner_tree.jl")
include("traversals/dfs.jl")
include("namedgraph.jl")
include("lib/NamedGraphGenerators/src/NamedGraphGenerators.jl")
include("lib/PartitionedGraphs/src/PartitionedGraphs.jl")

export NamedGraph, NamedDiGraph, NamedEdge

using PackageExtensionCompat: @require_extensions
function __init__()
  @require_extensions
end
end
