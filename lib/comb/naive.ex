defmodule Comb.Naive do
  @moduledoc false

  # This module implements naive implementations of each function in `Comb`. They
  # serve as reference implementations for testing and benchmarking. These
  # methods may return an `Enum` instead of a `Stream`.

  def cartesian_product(a, b), do: (for x <-a, y <-b, do: [x, y])
  
  def combinations(_, 0), do: [[]]

  def combinations([], _), do: []

  def combinations([h|t], k) do
    ((for l <- combinations(t, k - 1), do: [h|l]) ++ combinations(t, k))
    |> Enum.uniq
  end

  def combinations(enum, k), do: combinations(Enum.to_list(enum), k)

  def count_combinations(enum, k), do: combinations(enum, k) |> Enum.count
  
  def count_permutations(enum), do: permutations(enum) |> Enum.count
  
  def count_subsets(enum), do: subsets(enum) |> Enum.count
  
  def drop_permutations(enum, n), do: permutations(enum) |> Enum.drop(n)
  
  def nth_combination(enum, k, n), do: combinations(enum, k) |> Enum.fetch!(n)
  
  def nth_permutation(enum, n), do: permutations(enum) |> Enum.fetch!(n)
  
  def partitions(enum) do
    list = Enum.to_list enum
    n = Enum.count list
    Enum.flat_map(n..1, &(do_partition_for_size(list, &1)))
    |> Enum.uniq
  end

  defp do_partitions([]), do: [[]]

  defp do_partitions(list) do
    n = Enum.count list
    Enum.flat_map(n..1, &(do_partition_for_size(list, &1)))
  end
  # feilen ligger i at noe med flat/ikke flat map skal være annerledes i første
  # iterasjone

  defp do_partition_for_size(list, size) do
    list
    |> combinations(size)
    |> Enum.flat_map(fn comb ->
        do_partitions(list -- comb)
        |> Enum.map(&(Enum.sort([comb] ++ &1)))
      end)
  end


  def permutation_index(enum) do
    list = Enum.to_list enum
    list
    |> Enum.sort
    |> permutations
    |> Enum.find_index(fn p -> p == list end)
  end

  def permutations([]), do: [[]]

  def permutations(list) when is_list(list) do
    (for h <- list, t <- permutations(list -- [h]), do: [h | t])
    |> Enum.uniq
  end

  def permutations(enum), do: permutations(Enum.to_list(enum))

  def selections(_, 0), do: [[]]

  def selections(enum, n) do
    list = Enum.to_list enum
    list
    |> Enum.flat_map(fn el -> Enum.map(selections(list, n - 1), &([el | &1])) end)
  end

  def subsets(enum) do
    n = Enum.count enum
    0..n
    |> Enum.flat_map(&(do_subsets_for_n(enum, &1)))
  end

  defp do_subsets_for_n(enum, n) do
    enum
    |> combinations(n)
  end
end

