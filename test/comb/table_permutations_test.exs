defmodule Comb.TablePermutationsTest do
  use ExUnit.Case, async: true

  test "table algorithm works with [1, 2, 3]" do
    assert Comb.TablePermutations.permutations([1, 2, 3]) |> Enum.sort() ==
             [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]
  end

  test "table algorithm empty input" do
    assert Comb.TablePermutations.permutations([]) |> Enum.to_list() == [[]]
  end

  test "table algorithm benchmarked with naive" do
    assert Comb.TablePermutations.permutations(0..6) |> Enum.sort() ==
             Comb.Naive.permutations(0..6) |> Enum.sort()
  end
end
