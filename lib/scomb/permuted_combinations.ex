defmodule SComb.PermutedCombinations do
  @moduledoc false

  # Every combination, followed by every permutation of it. A combination
  # with counts t has k! / product of t! permutations, so a block of the
  # combinations that have t copies of their last value has C(k, t) times the
  # number of arrangements of k - t elements of the values before it. The
  # arrangements of j elements of a multiset are counted one value at a time:
  # j elements with i of them the new value can be placed in C(j, i) ways.

  alias SComb.{Combinations, Math, Multiset, Permutations}

  def permuted_combinations(enum, k),
    do: enum |> Combinations.combinations(k) |> Stream.flat_map(&Permutations.permutations/1)

  def count(enum, k) do
    enum |> Multiset.from_enum() |> Multiset.counts() |> arrangements(k) |> Enum.at(k)
  end

  def nth(enum, k, n) do
    multiset = Multiset.from_enum(enum)
    total = multiset |> Multiset.counts() |> arrangements(k) |> Enum.at(k)

    {combination, offset} =
      multiset |> with_arrangements_before(k) |> descend(k, Multiset.index!(n, total), 1, [])

    Permutations.nth(combination, offset)
  end

  # The numbers of arrangements of 0 to k elements of the values with counts
  defp arrangements(counts, k),
    do: Enum.reduce(counts, [1 | List.duplicate(0, k)], &multiply(&2, &1))

  # Adds a value that is there count times to the arrangements
  defp multiply(arrangements, count) do
    before = List.to_tuple(arrangements)

    for j <- 0..(tuple_size(before) - 1) do
      Enum.sum(for i <- 0..min(count, j), do: Math.binomial(j, i) * elem(before, j - i))
    end
  end

  # Pairs each entry, from the last, with a tuple of the arrangements of the
  # entries before it
  defp with_arrangements_before(multiset, k) do
    {entries, _arrangements} =
      Enum.reduce(multiset, {[], arrangements([], k)}, fn {value, count}, {entries, before} ->
        {[{value, count, List.to_tuple(before)} | entries], multiply(before, count)}
      end)

    entries
  end

  # Finds the combination, built from its last value, and the index among its
  # permutations. m is the number of permutations each of the combinations of
  # the rest has by now.
  defp descend(_entries, 0, n, _m, acc), do: {acc, n}

  defp descend([{value, count, before} | rest], k, n, m, acc),
    do: take(0, min(count, k), value, rest, before, k, n, m, acc)

  # Takes t copies of the value, fewest first, as the combinations do
  defp take(t, most, value, rest, before, k, n, m, acc) do
    m_t = m * Math.binomial(k, t)
    block = m_t * elem(before, k - t)

    if n < block or t == most do
      descend(rest, k - t, n, m_t, Multiset.dup(value, t, acc))
    else
      take(t + 1, most, value, rest, before, k, n - block, m, acc)
    end
  end
end
