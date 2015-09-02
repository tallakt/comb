defmodule Comb do
  # unfortunately exdoc doesnt support ``` fenced blocks
  @moduledoc (
    File.read!("README.md")
    |> String.split("\n") 
    |> Enum.reject(&(String.match?(&1, ~r/```|Build Status|Documentation Status/)))
    |> Enum.join("\n")
    )


  @doc """
  This function returns a list containing all combinations of one element
  from each `a` and `b`

  ## Example

      iex> cartesian_product(1..2, 3..4)
      [[1, 3], [1, 4], [2, 3], [2, 4]]

  """
  @spec cartesian_product(Enum.t, Enum.t) :: [list]
  def cartesian_product(a, b) do
    for x <- a, y <- b, do: [x, y]
  end
  

  @doc """
  Returns any combination of the elements in `enum` with exactly `k` elements.
  Repeated elements are handled intelligently.

  ## Examples

      iex> combinations([1, 2, 3], 2) |> Enum.to_list
      [[1, 2], [1, 3], [2, 3]]

      iex> combinations([1, 1, 2], 2) |> Enum.to_list
      [[1, 1], [1, 2]]

  """
  @spec combinations(Enum.t, integer) :: Enum.t
  def combinations(enum, k) do
    List.last(do_combinations(enum, k))
    |> Enum.uniq
  end

  defp do_combinations(enum, k) do
    combinations_by_length = [[[]]|List.duplicate([], k)]

    list = Enum.to_list(enum)
    List.foldr list, combinations_by_length, fn x, next ->
      sub = :lists.droplast(next)
      step = [[]|(for l <- sub, do: (for s <- l, do: [x|s]))]
      :lists.zipwith(&:lists.append/2, step, next)
    end
  end

  @doc """
  Returns the number of elements `combinations/2` would have returned.

  ## Examples

      iex> count_combinations([1, 2, 3], 2)
      3

  """
  @spec count_combinations(Enum.t, integer) :: Enum.integer
  def count_combinations(enum, k), do: combinations(enum, k) |> Enum.count
  
  @doc """
  Returns the nth combination that `combinations/2` would have returned. `n` is
  zero based.

  ## Examples

      iex> nth_combination([1, 2, 3], 2, 1)
      [1, 3]

  """
  @spec nth_combination(Enum.t, integer, integer) :: list | no_return
  def nth_combination(enum, k, n), do: combinations(enum, k) |> Enum.fetch!(n)
  
  @doc """
  Partitions `enum` into any groups in sum containing all elements.

  ## Examples

      iex> partitions(1..2) |> Enum.to_list
      [[[1, 2]], [[1], [2]]]

      iex> partitions([1, 1, 2]) |> Enum.to_list
      [[[1, 1, 2]], [[1, 1], [2]], [[1], [1, 2]], [[1], [1], [2]]]

  """
  @spec partitions(Enum.t) :: Enum.t
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

  defp do_partition_for_size(list, size) do
    list
    |> combinations(size)
    |> Enum.flat_map(fn comb ->
        do_partitions(list -- comb)
        |> Enum.map(&(Enum.sort([comb] ++ &1)))
      end)
  end

  @doc """
  Returns a stream containing all permutations of the input `enum`. A
  permutation will contain all elements in a different order. Repeated elements
  are handled sensibly.

  ## Examples

      iex> permutations(1..3) |> Enum.to_list
      [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]

      iex> permutations([1, 1, 2]) |> Enum.to_list
      [[1, 1, 2], [1, 2, 1], [2, 1, 1]]

  """
  @spec permutations(Enum.t) :: Enum.t
  defdelegate permutations(enum), to: Comb.Naive
  # At the moment this one returns permutations in incorrect order
  # defdelegate permutations(enum), to: Comb.TablePermutations

  @doc """
  Returns the number of elements `permutations/1` would have returned.

  ## Examples

      iex> count_permutations([1, 2, 3])
      6

  """
  @spec count_permutations(Enum.t) :: integer
  def count_permutations(enum), do: permutations(enum) |> Enum.count
  
  @doc """
  Calculates permutations starting from element `n` where `n` is zero based.
  This is more eficient than combining `permutations/1` and `Stream.drop/2`

  ## Examples

      iex> drop_permutations([1, 2, 3], 2) |> Enum.to_list
      [[2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]

  """
  @spec drop_permutations(Enum.t, integer) :: Enum.t
  def drop_permutations(enum, n), do: permutations(enum) |> Stream.drop(n)
  
  @doc """
  Returns the nth permutation that `permutations/1` would have returned. `n` is
  zero based.

  ## Examples

      iex> nth_permutation([1, 2, 3], 1)
      [1, 3, 2]

  """
  @spec nth_permutation(Enum.t, integer) :: list
  def nth_permutation(enum, n), do: permutations(enum) |> Enum.fetch!(n)
  
  @doc """
  Returns the index in the result of what `permutations/1` would return, if
  `permutations/1` was called with `enum` sorted. `n` is zero based.

  ## Examples

      iex> permutation_index([1, 3, 2])
      1

      iex> nth_permutation([1, 2, 3], 1)
      [1, 3, 2]

  """
  @spec permutation_index(Enum.t) :: integer
  def permutation_index(enum) do
    list = Enum.to_list enum
    list
    |> Enum.sort
    |> permutations
    |> Enum.find_index(fn p -> p == list end)
  end


  @doc """
  Returns a list containing all selections of the input `enum`. A selection
  will contain `k` elements each from `enum`.

  ## Examples

      iex> selections(1..3, 2) |> Enum.to_list
      [[1, 1], [1, 2], [1, 3], [2, 1], [2, 2], [2, 3], [3, 1], [3, 2], [3, 3]]

  """
  @spec selections(Enum.t, integer) :: Enum.t
  def selections(_, 0), do: [[]]

  def selections(enum, n) do
    list = Enum.to_list enum
    list
    |> Enum.flat_map(fn el -> Enum.map(selections(list, n - 1), &([el | &1])) end)
  end

  @doc """
  Returns a list containing all sets possible with any combination of elements
  in `enum`.

  ## Examples

      iex> subsets(1..3) |> Enum.to_list
      [[], [1], [2], [3], [1, 2], [1, 3], [2, 3], [1, 2, 3]]

      iex> subsets([1, 1, 2]) |> Enum.to_list
      [[], [1], [2], [1, 1], [1, 2], [1, 1, 2]]

  """
  @spec subsets(Enum.t) :: Enum.t
  def subsets(enum) do
    n = Enum.count enum
    0..n
    |> Stream.flat_map(&(do_subsets_for_n(enum, &1)))
  end

  defp do_subsets_for_n(enum, n) do
    enum
    |> combinations(n)
  end

  @doc """
  Returns the number of elements `subsets/1` would have returned.

  ## Examples

      iex> count_subsets([1, 2, 3])
      8

  """
  @spec count_subsets(Enum.t) :: integer
  def count_subsets(enum), do: subsets(enum) |> Enum.count
end
