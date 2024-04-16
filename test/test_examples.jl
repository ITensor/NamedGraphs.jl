@eval module $(gensym())
using NamedGraphs: NamedGraphs
using Suppressor: @suppress
using Test: @test, @testset
filenames = filter(endswith(".jl"), readdir(joinpath(pkgdir(NamedGraphs), "examples")))
@testset "Run examples: $filename" for filename in filenames
  @test Returns(true)(
    @suppress include(joinpath(pkgdir(NamedGraphs), "examples", filename))
  )
end
end
