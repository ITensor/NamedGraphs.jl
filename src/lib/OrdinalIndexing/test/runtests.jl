@eval module $(gensym())
using NamedGraphs.OrdinalIndexing: One, 𝟏
using NamedGraphs.OrdinalIndexing: OrdinalSuffixedInteger, th
using Test: @test, @test_broken, @test_throws, @testset
@testset "OrdinalIndexing" begin
  @testset "One" begin
    @test One() === 𝟏
    @test One() == 1
    @test 𝟏 * 2 === 2
    @test 2 * 𝟏 === 2
    @test 2 + 𝟏 === 3
    @test 𝟏 + 2 === 3
    @test 2 - 𝟏 === 1
    @test 𝟏 - 2 === -1
  end
  @testset "OrdinalSuffixedInteger" begin
    @test th === OrdinalSuffixedInteger(𝟏)
    @test 1th === OrdinalSuffixedInteger(1)
    @test 2th === OrdinalSuffixedInteger(2)
    @test_throws ArgumentError -1th
    r = (2th):(4th)
    @test r isa UnitRange{OrdinalSuffixedInteger{Int}}
    @test r === (2:4)th
    r = Base.OneTo(4th)
    @test r isa Base.OneTo{OrdinalSuffixedInteger{Int}}
    @test r === Base.OneTo(4)th
    for r in ((1:4)th, Base.OneTo(4)th)
      @test first(r) === 1th
      @test step(r) === 1th
      @test last(r) === 4th
      @test length(r) === 4th
      @test collect(r) == [1th, 2th, 3th, 4th]
    end
    @testset "$suffix1, $suffix2" for (suffix1, suffix2) in ((th, th), (th, 𝟏), (𝟏, th))
      @test 2suffix1 + 3suffix2 === 5th
      @test 4suffix1 - 2suffix2 === 2th
      @test 2suffix1 * 3suffix2 === 6th
      @test 2suffix1 < 3suffix2
      @test !(2suffix1 < 2suffix2)
      @test !(3suffix1 < 2suffix2)
      @test !(2suffix1 > 3suffix2)
      @test !(2suffix1 > 2suffix2)
      @test 3suffix1 > 2suffix2
      @test 2suffix1 <= 3suffix2
      @test 2suffix1 <= 2suffix2
      @test !(3suffix1 <= 2suffix2)
      @test !(2suffix1 >= 3suffix2)
      @test 2suffix1 >= 2suffix2
      @test 3suffix1 >= 2suffix2
    end
  end
end
end
