defmodule SComb.PermutedCombinations do
  @moduledoc false

  # Every combination, followed by every permutation of it. A combination
  # with counts t has k! / product of t! permutations, so a block of the
  # combinations that start with t copies of a value has C(k, t) times the
  # number of arrangements of k - t elements of the values after it. The
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
      multiset |> with_arrangements_after(k) |> descend(k, Multiset.index!(n, total), 1)

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

  # Pairs each entry with a tuple of the arrangements of the entries after it
  defp with_arrangements_after(multiset, k) do
    {entries, _arrangements} =
      List.foldr(multiset, {[], arrangements([], k)}, fn {value, count}, {entries, after_} ->
        {[{value, count, List.to_tuple(after_)} | entries], multiply(after_, count)}
      end)

    entries
  end

  # Finds the combination, and the index among its permutations. m is the
  # number of permutations each of the combinations of the rest has by now.
  defp descend(_entries, 0, n, _m), do: {[], n}

  defp descend([{value, count, after_} | rest], k, n, m),
    do: take(min(count, k), value, rest, after_, k, n, m)

  defp take(0, _value, rest, _after, k, n, m), do: descend(rest, k, n, m)

  defp take(t, value, rest, after_, k, n, m) do
    m_t = m * Math.binomial(k, t)
    block = m_t * elem(after_, k - t)

    if n < block do
      {combination, n} = descend(rest, k - t, n, m_t)
      {Multiset.dup(value, t, combination), n}
    else
      take(t - 1, value, rest, after_, k, n - block, m)
    end
  end
end
