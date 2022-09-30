using Test
using Graphs
using NamedGraphs
using Random

@testset "Comb tree constructors" begin
  Random.seed!(1234)

  # construct from tuple dimension
  dim = (rand(2:5), rand(1:5))
  ct1 = comb_tree(dim)
  @test nv(ct1) == prod(dim)
  @test ne(ct1) == prod(dim) - 1
  nct1 = named_comb_tree(dim)
  @show vertices
  for v in Graphs.vertices(nct1) # naming collising with other test
    for n in neighbors(nct1, v)
      if v[2] == 1
        @test ((abs.(v .- n) == (1, 0)) ⊻ (abs.(v .- n) == (0, 1)))
      else
        @test (abs.(v .- n) == (0, 1))
      end
    end
  end

  # construct from random vector of tooth lengths
  tooth_lengths = rand(1:5, rand(2:5))
  ct2 = comb_tree(tooth_lengths)
  @test nv(ct2) == sum(tooth_lengths)
  @test ne(ct2) == sum(tooth_lengths) - 1
  nct2 = named_comb_tree(tooth_lengths)
  for v in Graphs.vertices(nct2) # naming collising with other test
    for n in neighbors(nct2, v)
      if v[2] == 1
        @test ((abs.(v .- n) == (1, 0)) ⊻ (abs.(v .- n) == (0, 1)))
      else
        @test (abs.(v .- n) == (0, 1))
      end
    end
  end
end
