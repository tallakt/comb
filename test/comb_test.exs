defmodule CombTest do
  use ExUnit.Case, async: true

  doctest Comb.Wless1, import: true
  doctest Comb.Table, import: true
  doctest Comb, import: true

  test "table algorithm works with [1, 2, 3]" do
    assert Comb.Table.permutation([1, 2, 3]) |> Enum.sort ==
      [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]
  end

  test "table algorithm empty input" do
    assert Comb.Table.permutation([]) |> Enum.to_list == [[]]
  end

  test "table algorithm benchmarked with naive" do
    assert Comb.Table.permutation(0..6) |> Enum.sort == 
      Comb.Naive.permutations(0..6) |> Enum.sort
  end
end
