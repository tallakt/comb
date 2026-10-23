defmodule SCombTest do
  use ExUnit.Case, async: true
  import SComb
  alias SComb.Naive
  doctest SComb, import: true

  # Every list of up to five of a, b and c, covering repeated elements in any
  # order, and some longer and unsorted inputs
  defp inputs do
    Enum.flat_map(0..5, &Naive.selections([:a, :b, :c], &1)) ++
      [Enum.to_list(1..6), [3, 1, 2, 5, 4], [2, 1, 2, 3, 1, 1]]
  end

  describe "same results as the naive implementation" do
    test "permutations, count, nth and drop" do
      for input <- inputs() do
        expected = Naive.permutations(input)
        assert Enum.to_list(permutations(input)) == expected, inspect(input)
        assert count_permutations(input) == length(expected), inspect(input)

        for {permutation, n} <- Enum.with_index(expected) do
          assert nth_permutation(input, n) == permutation, inspect({input, n})
        end

        for n <- 0..(length(expected) + 1) do
          assert Enum.to_list(drop_permutations(input, n)) == Enum.drop(expected, n),
                 inspect({input, n})
        end
      end
    end

    test "permutation_index" do
      for input <- inputs(),
          {permutation, n} <- Enum.with_index(Naive.permutations(Enum.sort(input))) do
        assert permutation_index(permutation) == n, inspect(permutation)
      end
    end

    test "combinations, count and nth" do
      for input <- inputs(), k <- 0..(length(input) + 1) do
        expected = Naive.combinations(input, k)
        assert Enum.to_list(combinations(input, k)) == expected, inspect({input, k})
        assert count_combinations(input, k) == length(expected), inspect({input, k})

        for {combination, n} <- Enum.with_index(expected) do
          assert nth_combination(input, k, n) == combination, inspect({input, k, n})
        end
      end
    end

    test "subsets, count and nth" do
      for input <- inputs() do
        expected = Naive.subsets(input)
        assert Enum.to_list(subsets(input)) == expected, inspect(input)
        assert count_subsets(input) == length(expected), inspect(input)

        for {subset, n} <- Enum.with_index(expected) do
          assert nth_subset(input, n) == subset, inspect({input, n})
        end
      end
    end

    test "selections" do
      for input <- inputs(), length(input) <= 4, k <- 0..3 do
        assert Enum.to_list(selections(input, k)) == Naive.selections(input, k),
               inspect({input, k})
      end
    end

    test "partitions" do
      for input <- inputs() do
        assert Enum.to_list(partitions(input)) == Naive.partitions(input), inspect(input)
      end
    end

    test "partitions with min and max blocks" do
      for input <- inputs(), opts <- [[min: 2], [max: 2], [min: 2, max: 3], [min: 4, max: 1]] do
        assert Enum.to_list(partitions(input, opts)) == Naive.partitions(input, opts),
               inspect({input, opts})
      end
    end

    test "permuted_combinations" do
      for input <- inputs(), k <- 0..(length(input) + 1) do
        assert Enum.to_list(permuted_combinations(input, k)) ==
                 Naive.permuted_combinations(input, k),
               inspect({input, k})
      end
    end

    test "cartesian_product" do
      for enums <- [[], [1..3], [1..2, [], 1..2], [1..2, [:a, :a], 3..5], List.duplicate(1..3, 4)] do
        assert Enum.to_list(cartesian_product(enums)) == Naive.cartesian_product(enums)
      end
    end

    test "inputs large enough to be streamed" do
      assert Enum.to_list(combinations(1..14, 7)) == Naive.combinations(1..14, 7)
      repeated = [1, 1, 1, 2, 2, 2, 3, 3, 4, 5, 6, 7, 8, 9]
      assert Enum.to_list(combinations(repeated, 6)) == Naive.combinations(repeated, 6)
      assert Enum.to_list(partitions(1..10)) == Naive.partitions(1..10)
      repeated = [1, 1, 2, 2, 3, 3, 4, 4, 5, 6]
      assert Enum.to_list(partitions(repeated)) == Naive.partitions(repeated)
      assert Enum.to_list(selections(1..5, 6)) == Naive.selections(1..5, 6)
    end
  end

  test "huge results are streamed lazily" do
    assert permutations(1..1000) |> Enum.take(2) ==
             [Enum.to_list(1..1000), [2, 1 | Enum.to_list(3..1000)]]

    assert combinations(1..1000, 500) |> Enum.take(1) == [Enum.to_list(1..500)]
    assert subsets(1..1000) |> Enum.take(3) == [[], [1], [2]]
    assert selections(1..10, 100) |> Enum.take(1) == [List.duplicate(1, 100)]

    assert cartesian_product(List.duplicate(1..10, 100)) |> Enum.take(1) == [
             List.duplicate(1, 100)
           ]

    assert partitions(1..100) |> Enum.take(2) == [
             [Enum.to_list(1..100)],
             [Enum.to_list(1..99), [100]]
           ]
  end

  test "nth, drop and index work far into huge results" do
    n = 10 ** 30
    permutation = nth_permutation(1..30, n)
    assert drop_permutations(1..30, n) |> Enum.take(1) == [permutation]
    assert permutation_index(permutation) == n

    # 40! / 10!^4, about 4.7 * 10^21 permutations
    repeated = Enum.map(1..40, &rem(&1, 4)) |> Enum.sort()
    n = 10 ** 20
    permutation = nth_permutation(repeated, n)
    assert permutation_index(permutation) == n
    assert drop_permutations(repeated, n) |> Enum.at(1) == nth_permutation(repeated, n + 1)

    count = count_combinations(1..100, 50)
    assert count == SComb.Math.binomial(100, 50)
    assert nth_combination(1..100, 50, count - 1) == Enum.to_list(51..100)
    assert nth_subset(1..100, -1) == Enum.to_list(1..100)
  end

  test "empty results and empty inputs" do
    assert Enum.to_list(permutations([])) == [[]]
    assert count_permutations([]) == 1
    assert permutation_index([]) == 0
    assert Enum.to_list(combinations([], 0)) == [[]]
    assert Enum.to_list(combinations(1..3, 4)) == []
    assert count_combinations(1..3, 4) == 0
    assert Enum.to_list(subsets([])) == [[]]
    assert Enum.to_list(partitions([])) == [[]]
    assert Enum.to_list(selections([], 2)) == []
    assert Enum.to_list(selections(1..3, 0)) == [[]]
    assert Enum.to_list(cartesian_product([1..2, []])) == []
    assert Enum.to_list(drop_permutations(1..3, 6)) == []
  end

  test "negative indexes count from the end" do
    assert nth_permutation(1..3, -1) == [3, 2, 1]
    assert nth_combination(1..4, 2, -1) == [3, 4]
    assert nth_subset(1..3, -1) == [1, 2, 3]
    assert Enum.to_list(drop_permutations(1..3, -4)) == [[1, 2, 3], [2, 1, 3]]
  end

  test "indexes out of bounds raise" do
    assert_raise Enum.OutOfBoundsError, fn -> nth_permutation(1..3, 6) end
    assert_raise Enum.OutOfBoundsError, fn -> nth_permutation(1..3, -7) end
    assert_raise Enum.OutOfBoundsError, fn -> nth_combination(1..3, 4, 0) end
    assert_raise Enum.OutOfBoundsError, fn -> nth_subset([], 1) end
  end

  test "negative sizes raise" do
    assert_raise FunctionClauseError, fn -> combinations(1..3, -1) end
    assert_raise FunctionClauseError, fn -> selections(1..3, -1) end
  end
end
