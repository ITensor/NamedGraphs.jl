using NamedGraphs.GraphsExtensions: is_arranged

@testset "arrange" begin
  @testset "is_arranged" begin
    for (a, b) in [
      (1, 2),
      ([1], [2]),
      ([1, 2], [2, 1]),
      ([1, 2], [2]),
      ([2], [2, 1]),
      ((1,), (2,)),
      ((1, 2), (2, 1)),
      ((1, 2), (2,)),
      ((2,), (2, 1)),
      ("X", 1),
      (("X",), (1, 2)),
    ]
      @test is_arranged(a, b)
      @test !is_arranged(b, a)
    end
  end
end
