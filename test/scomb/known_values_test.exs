defmodule SComb.KnownValuesTest do
  use ExUnit.Case, async: true
  import SComb

  # Hand-written expected results that any combinatorics implementation would
  # give. SComb does not promise the order of its results, so they are
  # compared sorted where the order is not a standard one, and partitions with
  # their blocks sorted too.

  defp sorted(enum), do: enum |> Enum.to_list() |> Enum.sort()
  defp sorted_partitions(enum), do: enum |> Enum.map(&Enum.sort/1) |> Enum.sort()

  test "combinations" do
    assert sorted(combinations([1, 2, 3], 2)) == [[1, 2], [1, 3], [2, 3]]
    assert sorted(combinations([1, 1, 2], 2)) == [[1, 1], [1, 2]]
    assert count_combinations(1..5, 3) == 10
  end

  test "subsets" do
    assert sorted(subsets([1, 2, 3])) ==
             Enum.sort([[], [1], [2], [3], [1, 2], [1, 3], [2, 3], [1, 2, 3]])

    assert count_subsets([1, 2, 3]) == 8
    assert count_subsets([1, 1, 2]) == 6
  end

  test "cartesian_product" do
    assert cartesian_product([1, 2], [3, 4]) == [[1, 3], [1, 4], [2, 3], [2, 4]]
  end

  test "selections" do
    assert Enum.to_list(selections([0, 1], 3)) ==
             [
               [0, 0, 0],
               [0, 0, 1],
               [0, 1, 0],
               [0, 1, 1],
               [1, 0, 0],
               [1, 0, 1],
               [1, 1, 0],
               [1, 1, 1]
             ]
  end

  test "permutations" do
    assert permutations([1, 2, 3]) |> Enum.sort() ==
             [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]

    assert permutations([1, 1, 2]) |> Enum.sort() == [[1, 1, 2], [1, 2, 1], [2, 1, 1]]
    assert count_permutations([1, 2, 3]) == 6
    assert count_permutations([1, 1, 2, 2]) == 6
  end

  test "permuted_combinations" do
    assert permuted_combinations([1, 2, 3], 2) |> Enum.sort() ==
             [[1, 2], [1, 3], [2, 1], [2, 3], [3, 1], [3, 2]]

    assert permuted_combinations([1, 1, 2], 2) |> Enum.sort() == [[1, 1], [1, 2], [2, 1]]
    assert Enum.to_list(permuted_combinations(1..3, 0)) == [[]]
    assert Enum.to_list(permuted_combinations(1..3, 4)) == []

    # n! / (n - k)! ways of picking k of n distinct elements in order
    assert Enum.count(permuted_combinations(1..6, 3)) == 120
    assert Enum.count(permuted_combinations(1..10, 4)) == 5040
  end

  test "permuted_combinations is lazy" do
    assert permuted_combinations(1..1000, 500) |> Enum.take(1) |> hd |> Enum.take(3) ==
             [1, 2, 3]
  end

  # The number of partitions of n distinct elements into k blocks is the
  # Stirling number of the second kind
  describe "partitions with :min and :max" do
    test "block counts follow the Stirling numbers" do
      assert Enum.count(partitions(1..4)) == 15
      assert Enum.count(partitions(1..4, min: 2, max: 3)) == 7 + 6
      assert Enum.count(partitions(1..4, min: 2)) == 7 + 6 + 1
      assert Enum.count(partitions(1..4, max: 2)) == 1 + 7
      assert Enum.count(partitions(1..4, min: 3, max: 3)) == 6
    end

    test "all blocks are within the bounds" do
      for p <- partitions(1..5, min: 2, max: 3), do: assert(length(p) in 2..3)
    end

    test "bounds that do not restrict anything" do
      assert Enum.to_list(partitions(1..4, min: 0)) == Enum.to_list(partitions(1..4))
      assert Enum.to_list(partitions(1..4, min: -3)) == Enum.to_list(partitions(1..4))
      assert Enum.to_list(partitions(1..4, max: 99)) == Enum.to_list(partitions(1..4))
      assert Enum.to_list(partitions(1..4, [])) == Enum.to_list(partitions(1..4))
    end

    test "bounds that nothing satisfies" do
      assert Enum.to_list(partitions(1..4, min: 5)) == []
      assert Enum.to_list(partitions(1..4, max: 0)) == []
      assert Enum.to_list(partitions(1..4, min: 3, max: 2)) == []
    end

    test "the empty input has a partition of no blocks" do
      assert Enum.to_list(partitions([], max: 0)) == [[]]
      assert Enum.to_list(partitions([], min: 1)) == []
    end

    test "repeated elements" do
      assert sorted_partitions(partitions([1, 1, 2], min: 2, max: 2)) ==
               sorted_partitions([[[1, 1], [2]], [[1, 2], [1]]])
    end

    test "limits are applied while generating, not by filtering all partitions" do
      # Far too many partitions to filter: Bell(40) is about 1.6 * 10^35
      assert Enum.count(partitions(1..40, min: 39)) == div(40 * 39, 2) + 1
      assert Enum.count(partitions(1..40, min: 40)) == 1
      assert Enum.count(partitions(1..60, max: 1)) == 1
      # Stirling number of the second kind S(16, 2), plus one block
      assert Enum.count(partitions(1..16, max: 2)) == 2 ** 15
    end

    test "large inputs are still lazy" do
      [partition] = partitions(1..100, min: 2) |> Enum.take(1)
      assert length(partition) >= 2
      assert partition |> Enum.concat() |> Enum.sort() == Enum.to_list(1..100)
    end
  end
end
