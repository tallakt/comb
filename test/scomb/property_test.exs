defmodule SComb.PropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  import SComb
  alias SComb.{Math, Naive}

  # Lists with few distinct values, so most have repeated elements, of up to
  # max_length. Sizes run past the points where the algorithms switch from
  # building lists to streams. Equal elements are told apart with ===, so the
  # mixed pool has 1 and 1.0 apart.
  defp ints(max_length), do: list_of(member_of([1, 2, 3, 4, 5]), max_length: max_length)

  defp mixed(max_length),
    do: list_of(member_of([1, 1.0, :a, "a", [1], {1}]), max_length: max_length)

  defp lists(max_length), do: one_of([ints(max_length), mixed(max_length)])

  # Naive has to generate everything, so the sizes it can handle are limited
  @runs 600

  # For the properties that make a lot of calls for each input
  @few_runs 100

  describe "same results as the naive implementation" do
    property "permutations" do
      check all(list <- lists(7), max_runs: @runs) do
        assert Enum.to_list(permutations(list)) == Naive.permutations(list)
      end
    end

    property "combinations" do
      check all(list <- lists(13), k <- integer(0..14), max_runs: @runs) do
        assert Enum.to_list(combinations(list, k)) == Naive.combinations(list, k)
      end
    end

    property "subsets" do
      check all(list <- lists(12), max_runs: @runs) do
        assert Enum.to_list(subsets(list)) == Naive.subsets(list)
      end
    end

    property "partitions" do
      check all(list <- lists(9), max_runs: @runs) do
        assert Enum.to_list(partitions(list)) == Naive.partitions(list)
      end
    end

    property "partitions with :min and :max" do
      check all(list <- lists(8), min <- integer(0..4), max <- integer(0..9), max_runs: @runs) do
        opts = [min: min, max: max]
        assert Enum.to_list(partitions(list, opts)) == Naive.partitions(list, opts)
      end
    end

    property "permuted_combinations" do
      check all(list <- lists(6), k <- integer(0..7), max_runs: @runs) do
        assert Enum.to_list(permuted_combinations(list, k)) ==
                 Naive.permuted_combinations(list, k)
      end
    end

    property "selections" do
      check all(list <- lists(4), k <- integer(0..3), max_runs: @runs) do
        assert Enum.to_list(selections(list, k)) == Naive.selections(list, k)
      end
    end
  end

  describe "the count and nth functions agree with the naive implementation" do
    property "partitions" do
      check all(list <- lists(9), max_runs: @few_runs) do
        expected = Naive.partitions(list)
        assert count_partitions(list) == length(expected)

        # Every nth partition is slow for the largest inputs, so look at some
        step = max(1, div(length(expected), 40))

        for {partition, n} <- Enum.with_index(expected), rem(n, step) == 0 do
          assert nth_partition(list, n) == partition
        end

        assert nth_partition(list, -1) == List.last(expected)
      end
    end

    property "selections" do
      check all(list <- lists(4), k <- integer(0..3), max_runs: @runs) do
        expected = Naive.selections(list, k)
        assert count_selections(list, k) == length(expected)

        for {selection, n} <- Enum.with_index(expected) do
          assert nth_selection(list, k, n) == selection
        end
      end
    end

    property "permuted_combinations" do
      check all(list <- lists(5), k <- integer(0..5), max_runs: @few_runs) do
        expected = Naive.permuted_combinations(list, k)
        assert count_permuted_combinations(list, k) == length(expected)

        for {element, n} <- Enum.with_index(expected) do
          assert nth_permuted_combination(list, k, n) == element
        end
      end
    end

    property "cartesian_product" do
      check all(enums <- list_of(lists(3), max_length: 4), max_runs: @runs) do
        expected = Naive.cartesian_product(enums)
        assert Enum.to_list(cartesian_product(enums)) == expected
        assert count_cartesian_product(enums) == length(expected)

        for {element, n} <- Enum.with_index(expected) do
          assert nth_cartesian_product(enums, n) == element
        end
      end
    end

    property "combinations_with_replacement" do
      check all(list <- lists(5), k <- integer(0..4), max_runs: @runs) do
        expected = Naive.combinations_with_replacement(list, k)
        assert Enum.to_list(combinations_with_replacement(list, k)) == expected
        assert count_combinations_with_replacement(list, k) == length(expected)

        for {combination, n} <- Enum.with_index(expected) do
          assert nth_combination_with_replacement(list, k, n) == combination
        end
      end
    end
  end

  describe "properties of large results" do
    property "nth_partition agrees with the start of the stream" do
      check all(list <- lists(11), max_runs: @few_runs) do
        for {partition, n} <- partitions(list) |> Enum.take(20) |> Enum.with_index() do
          assert nth_partition(list, n) == partition
        end

        assert nth_partition(list, -1) == nth_partition(list, count_partitions(list) - 1)
      end
    end

    property "indexing a sequence agrees with the nth functions" do
      check all(
              list <- ints(30),
              k <- integer(0..30),
              fraction <- float(min: 0.0, max: 0.999),
              max_runs: @runs
            ) do
        at = fn sequence, count -> {Enum.count(sequence), trunc(count * fraction)} end

        {count, i} = at.(permutations(list), count_permutations(list))
        assert count == count_permutations(list)
        assert Enum.at(permutations(list), i) == nth_permutation(list, i)

        {_, i} = at.(combinations(list, k), count_combinations(list, k))

        if count_combinations(list, k) > 0,
          do: assert(Enum.at(combinations(list, k), i) == nth_combination(list, k, i))

        {_, i} = at.(subsets(list), count_subsets(list))
        assert Enum.at(subsets(list), i) == nth_subset(list, i)

        {_, i} = at.(selections(list, k), count_selections(list, k))

        if count_selections(list, k) > 0,
          do: assert(Enum.at(selections(list, k), i) == nth_selection(list, k, i))
      end
    end

    property "nth_permutation and permutation_index are inverses" do
      check all(list <- ints(40), shuffled <- shuffle(list), max_runs: @runs) do
        n = permutation_index(shuffled)
        assert nth_permutation(Enum.sort(shuffled), n) == shuffled
      end
    end

    property "drop_permutations starts at nth_permutation" do
      check all(
              list <- ints(30),
              list != [],
              fraction <- float(min: 0.0, max: 0.999),
              max_runs: @runs
            ) do
        n = trunc(count_permutations(list) * fraction)
        assert drop_permutations(list, n) |> Enum.take(1) == [nth_permutation(list, n)]
      end
    end

    property "count_permutations is the multinomial of the counts" do
      check all(list <- ints(40), max_runs: @runs) do
        counts = list |> Enum.frequencies() |> Map.values()

        expected =
          div(Math.factorial(length(list)), Enum.reduce(counts, 1, &(&2 * Math.factorial(&1))))

        assert count_permutations(list) == expected
      end
    end

    property "count_subsets multiplies one more than each count" do
      check all(list <- ints(40), max_runs: @runs) do
        expected = list |> Enum.frequencies() |> Map.values() |> Enum.reduce(1, &(&2 * (&1 + 1)))
        assert count_subsets(list) == expected
      end
    end

    property "count_combinations of distinct elements is the binomial" do
      check all(n <- integer(0..60), k <- integer(0..60), max_runs: @runs) do
        expected = if k > n, do: 0, else: Math.binomial(n, k)
        assert count_combinations(1..n//1, k) == expected
      end
    end

    property "nth_* agrees with the start of the stream" do
      check all(list <- ints(30), k <- integer(0..30), max_runs: @runs) do
        for {permutation, n} <- permutations(list) |> Enum.take(20) |> Enum.with_index() do
          assert nth_permutation(list, n) == permutation
        end

        for {combination, n} <- combinations(list, k) |> Enum.take(20) |> Enum.with_index() do
          assert nth_combination(list, k, n) == combination
        end

        for {subset, n} <- subsets(list) |> Enum.take(20) |> Enum.with_index() do
          assert nth_subset(list, n) == subset
        end
      end
    end

    property "the last elements agree with negative indexes" do
      check all(list <- ints(30), k <- integer(0..30), max_runs: @runs) do
        assert nth_permutation(list, -1) == nth_permutation(list, count_permutations(list) - 1)
        assert nth_subset(list, -1) == nth_subset(list, count_subsets(list) - 1)

        if count_combinations(list, k) > 0 do
          assert nth_combination(list, k, -1) ==
                   nth_combination(list, k, count_combinations(list, k) - 1)
        end
      end
    end
  end

  describe "properties of what is returned" do
    property "permutations are distinct rearrangements of the input" do
      check all(list <- lists(30), max_runs: @runs) do
        sorted = Enum.sort(list)
        taken = permutations(list) |> Enum.take(200)
        assert Enum.all?(taken, &(Enum.sort(&1) == sorted))
        assert taken == Enum.uniq(taken)
      end
    end

    property "combinations are distinct, of size k, and drawn from the input" do
      check all(list <- lists(30), k <- integer(0..12), max_runs: @runs) do
        taken = combinations(list, k) |> Enum.take(200)
        available = Enum.frequencies(list)

        assert taken == Enum.uniq(taken)

        for combination <- taken do
          assert length(combination) == k

          for {value, count} <- Enum.frequencies(combination),
              do: assert(count <= Map.fetch!(available, value))
        end
      end
    end

    property "partitions are distinct and hold exactly the input elements" do
      check all(list <- lists(14), max_runs: @runs) do
        sorted = Enum.sort(list)
        taken = partitions(list) |> Enum.take(200)
        assert taken == Enum.uniq(taken)
        assert Enum.all?(taken, &(&1 |> Enum.concat() |> Enum.sort() == sorted))
        assert Enum.all?(taken, &(&1 |> Enum.all?(fn block -> block != [] end)))
      end
    end
  end

  test "1 and 1.0 are different elements" do
    assert count_permutations([1, 1.0]) == 2
    assert count_permutations([1, 1]) == 1
    assert Enum.to_list(combinations([1, 1.0], 1)) == [[1], [1.0]]
    assert count_subsets([1, 1.0, 1]) == 6
  end
end
