defmodule PermutationsTest do
  use ExUnit.Case, async: true
  doctest Comb.Naive, import: true
  doctest Comb.Wless1, import: true
  doctest Comb.LazyPermutations, import: true
  doctest Comb.SJT, import: true

  test "sjt algorithm works with [1, 2, 3]" do
    assert Comb.SJT.permutation([1, 2, 3]) |> Enum.sort ==
      [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]
  end

  test "table algorithm works with [1, 2, 3]" do
    assert Comb.Table.permutation([1, 2, 3]) |> Enum.sort ==
      [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]
  end

  test "sjt algorithm works with [:one]" do
    assert Comb.SJT.permutation([:one]) |> Enum.sort == [[:one]]
  end

  test "sjt algorithm works with []" do
    assert Comb.SJT.permutation([]) |> Enum.sort == [[]]
  end

  test "@martin's algorithm benchmarked with naive" do
    enum = 10..14 |> Enum.to_list
    assert Comb.LazyPermutations.permutation(enum) |> Enum.sort == 
      Comb.Naive.permutation(enum) |> Enum.sort
  end

  test "table algorithm benchmarked with naive" do
    enum = 0..7 |> Enum.to_list
    assert Comb.Table.permutation(enum) |> Enum.sort == 
      Comb.Naive.permutation(enum) |> Enum.sort
  end

  test "sjt algorithm benchmarked with naive" do
    enum = 0..3 |> Enum.to_list
    assert Comb.SJT.permutation(enum) |> Enum.take(4*3*2+1) |> Enum.sort == 
      Comb.Naive.permutation(enum) |> Enum.sort
  end
end
