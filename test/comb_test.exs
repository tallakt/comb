defmodule CombTest do
  use ExUnit.Case, async: true
  import Comb
  doctest Comb, import: true

  test "count_permutations for a sequence with many repeated items" do
    assert count_permutations([1, 1, 2]) ==
      permutations([1, 1, 2]) |> Enum.count
    assert count_permutations([1, 1, 2, 2, 2, 3]) ==
      permutations([1, 1, 2, 2, 2, 3]) |> Enum.count
  end

end
