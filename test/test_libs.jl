@eval module $(gensym())
using NamedGraphs: NamedGraphs
using Test: @testset
libs = [
    #:GraphGenerators,
    :GraphsExtensions,
    #:Keys,
    #:NamedGraphGenerators,
    :OrderedDictionaries,
    :OrdinalIndexing,
    #:PartitionedGraphs,
    #:SimilarType,
]
@testset "Test lib $lib" for lib in libs
    path = joinpath(pkgdir(NamedGraphs), "src", "lib", String(lib), "test", "runtests.jl")
    println("Running lib test $path")
    include(path)
end
end
