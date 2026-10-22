defmodule SComb.Naive do
  @moduledoc false

  # This module implements naive implementations of each function in `SComb`. They
  # serve as reference implementations for testing and benchmarking, returning
  # the same elements in the same order. These methods may return an `Enum`
  # instead of a `Stream`.

  def cartesian_product(a, b), do: for(x <- a, y <- b, do: [x, y])

  def cartesian_product([]), do: [[]]

  def cartesian_product([enum | enums]),
    do: for(x <- enum, tail <- cartesian_product(enums), do: [x | tail])

  def combinations(enum, k), do: enum |> group() |> do_combinations(k)

  defp do_combinations(_, 0), do: [[]]

  defp do_combinations([], _), do: []

  defp do_combinations([h | t], k) do
    (for(l <- do_combinations(t, k - 1), do: [h | l]) ++ do_combinations(t, k))
    |> Enum.uniq()
  end

  def count_combinations(enum, k), do: combinations(enum, k) |> Enum.count()

  def count_permutations(enum), do: permutations(enum) |> Enum.count()

  def count_subsets(enum), do: subsets(enum) |> Enum.count()

  def drop_permutations(enum, n), do: permutations(enum) |> Enum.drop(n)

  def nth_combination(enum, k, n), do: combinations(enum, k) |> Enum.fetch!(n)

  def nth_permutation(enum, n), do: permutations(enum) |> Enum.fetch!(n)

  def nth_subset(enum, n), do: subsets(enum) |> Enum.fetch!(n)

  # The first block holds the first element, and any of the others, trying
  # those holding the most first. The blocks of each partition are sorted, more
  # of a value before less, and the first value before the next. Partitions
  # that are generated again are dropped.
  def partitions(enum) do
    list = group(enum)
    values = Enum.uniq(list)
    counts = fn block -> Enum.map(values, fn v -> Enum.count(block, &(&1 === v)) end) end

    list
    |> do_partitions()
    |> Enum.map(&Enum.sort_by(&1, counts, :desc))
    |> Enum.uniq()
  end

  defp do_partitions([]), do: [[]]

  defp do_partitions([h | t]) do
    for s <- subsets_most_first(t), rest <- do_partitions(t -- s), do: [[h | s] | rest]
  end

  defp subsets_most_first([]), do: [[]]

  defp subsets_most_first([h | t]) do
    subsets = subsets_most_first(t)
    for(s <- subsets, do: [h | s]) ++ subsets
  end

  def permutation_index(enum) do
    list = Enum.to_list(enum)

    list
    |> Enum.sort()
    |> permutations
    |> Enum.find_index(fn p -> p == list end)
  end

  # The last element is picked first, trying the values in reverse order of
  # first appearance
  def permutations(enum), do: enum |> group() |> do_permutations()

  defp do_permutations([]), do: [[]]

  defp do_permutations(list) do
    for h <- list |> Enum.uniq() |> Enum.reverse(),
        t <- do_permutations(list -- [h]),
        do: t ++ [h]
  end

  def selections(_, 0), do: [[]]

  def selections(enum, n) do
    list = Enum.uniq(enum)

    list
    |> Enum.flat_map(fn el -> Enum.map(selections(list, n - 1), &[el | &1]) end)
  end

  def subsets(enum) do
    n = Enum.count(enum)

    0..n
    |> Enum.flat_map(&do_subsets_for_n(enum, &1))
  end

  defp do_subsets_for_n(enum, n) do
    enum
    |> combinations(n)
  end

  # Repeated elements are interchangeable, so group them, in order of first
  # appearance
  defp group(enum) do
    list = Enum.to_list(enum)
    list |> Enum.uniq() |> Enum.flat_map(fn x -> Enum.filter(list, &(&1 === x)) end)
  end
end
