defmodule PermutationsTest do
  use ExUnit.Case, async: true
  doctest Permutations.Naive, import: true
  doctest Permutations.Wless1, import: true
  doctest Permutations.LazyPermutations, import: true
  doctest Permutations.TallakEnum, import: true
  doctest Permutations.TallakStream, import: true
  doctest Permutations.TallakMaps, import: true
  doctest Permutations.SJT, import: true

  test "sjt algorithm works with [1, 2, 3]" do
    assert Permutations.SJT.permutation([1, 2, 3]) |> Enum.sort ==
      [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]
  end

  test "sjt algorithm works with [:one]" do
    assert Permutations.SJT.permutation([:one]) |> Enum.sort == [[:one]]
  end

  test "sjt algorithm works with []" do
    assert Permutations.SJT.permutation([]) |> Enum.sort == [[]]
  end

  test "@martin's algorithm benchmarked with naive" do
    enum = 10..14 |> Enum.to_list
    assert Permutations.LazyPermutations.permutation(enum) |> Enum.sort == 
      Permutations.Naive.permutation(enum) |> Enum.sort
  end

  test "sjt algorithm benchmarked with naive" do
    enum = 0..3 |> Enum.to_list
    assert Permutations.SJT.permutation(enum) |> Enum.take(4*3*2+1) |> Enum.sort == 
      Permutations.Naive.permutation(enum) |> Enum.sort
  end
end
