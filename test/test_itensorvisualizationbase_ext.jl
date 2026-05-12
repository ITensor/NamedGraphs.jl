@eval module $(gensym())
using ITensorVisualizationBase: ITensorVisualizationBase
using NamedGraphs.NamedGraphGenerators: named_grid
using NamedGraphs: AbstractNamedGraph
using Test: @test, @testset

@testset "NamedGraphsITensorVisualizationBaseExt" begin
    g = named_grid((2, 2))
    @test hasmethod(ITensorVisualizationBase.visualize, Tuple{AbstractNamedGraph})
    @test ITensorVisualizationBase.visualize(g) === nothing
    @test ITensorVisualizationBase.visualize(g; vertex_labels_prefix = "v") === nothing
end
end
