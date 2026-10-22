defmodule Comb do
  # The README's examples run as doctests: drop the code fences around them,
  # and the CI badge
  @external_resource "README.md"
  @moduledoc File.read!("README.md")
             |> String.split("\n")
             |> Enum.reject(&String.match?(&1, ~r/```|actions\/workflows/))
             |> Enum.join("\n")

  alias Comb.{CartesianProduct, Combinations, Partitions, Permutations}

  @doc """
  This function returns a list containing all combinations of one element
  from each `a` and `b`

  ## Example

      iex> cartesian_product(1..2, 3..4)
      [[1, 3], [1, 4], [2, 3], [2, 4]]

  """
  @spec cartesian_product(Enum.t(), Enum.t()) :: [list]
  def cartesian_product(a, b) do
    for x <- a, y <- b, do: [x, y]
  end

  @doc """
  Returns all combinations of one element from each of the enumerables in
  `enums`.

  ## Examples

      iex> cartesian_product([1..2, [:a], 3..4]) |> Enum.to_list
      [[1, :a, 3], [1, :a, 4], [2, :a, 3], [2, :a, 4]]

      iex> cartesian_product([]) |> Enum.to_list
      [[]]

  """
  @spec cartesian_product([Enum.t()]) :: Enum.t()
  def cartesian_product(enums) when is_list(enums), do: CartesianProduct.product(enums)

  @doc """
  Returns any combination of the elements in `enum` with exactly `k` elements.
  Repeated elements are handled intelligently.

  ## Examples

      iex> combinations([1, 2, 3], 2) |> Enum.to_list
      [[1, 2], [1, 3], [2, 3]]

      iex> combinations([1, 1, 2], 2) |> Enum.to_list
      [[1, 1], [1, 2]]

  """
  @spec combinations(Enum.t(), non_neg_integer) :: Enum.t()
  def combinations(enum, k) when is_integer(k) and k >= 0,
    do: Combinations.combinations(enum, k)

  @doc """
  Returns the number of elements `combinations/2` would have returned.

  ## Examples

      iex> count_combinations([1, 2, 3], 2)
      3

      iex> count_combinations([1, 1, 2], 2)
      2

  """
  @spec count_combinations(Enum.t(), non_neg_integer) :: non_neg_integer
  def count_combinations(enum, k) when is_integer(k) and k >= 0, do: Combinations.count(enum, k)

  @doc """
  Returns the nth combination that `combinations/2` would have returned. `n` is
  zero based, and a negative `n` counts from the end.

  Raises `Enum.OutOfBoundsError` if there is no such combination.

  ## Examples

      iex> nth_combination([1, 2, 3], 2, 1)
      [1, 3]

  """
  @spec nth_combination(Enum.t(), non_neg_integer, integer) :: list | no_return
  def nth_combination(enum, k, n) when is_integer(k) and k >= 0 and is_integer(n),
    do: Combinations.nth(enum, k, n)

  @doc """
  Partitions `enum` into any groups in sum containing all elements.

  ## Examples

      iex> partitions(1..2) |> Enum.to_list
      [[[1, 2]], [[1], [2]]]

      iex> partitions([1, 1, 2]) |> Enum.to_list
      [[[1, 1, 2]], [[1, 1], [2]], [[1, 2], [1]], [[1], [1], [2]]]

  """
  @spec partitions(Enum.t()) :: Enum.t()
  def partitions(enum), do: Partitions.partitions(enum)

  @doc """
  Returns a stream containing all permutations of the input `enum`. A
  permutation will contain all elements in a different order. Repeated elements
  are handled sensibly.

  ## Examples

      iex> permutations(1..3) |> Enum.to_list
      [[1, 2, 3], [2, 1, 3], [1, 3, 2], [3, 1, 2], [2, 3, 1], [3, 2, 1]]

      iex> permutations([1, 1, 2]) |> Enum.to_list
      [[1, 1, 2], [1, 2, 1], [2, 1, 1]]

  """
  @spec permutations(Enum.t()) :: Enum.t()
  def permutations(enum), do: Permutations.permutations(enum)

  @doc """
  Returns the number of elements `permutations/1` would have returned.

  ## Examples

      iex> count_permutations([1, 2, 3])
      6

      iex> count_permutations([1, 1, 2])
      3

  """
  @spec count_permutations(Enum.t()) :: pos_integer
  def count_permutations(enum), do: Permutations.count(enum)

  @doc """
  Calculates permutations starting from element `n` where `n` is zero based.
  This is more efficient than combining `permutations/1` and `Stream.drop/2`

  ## Examples

      iex> drop_permutations([1, 2, 3], 2) |> Enum.to_list
      [[1, 3, 2], [3, 1, 2], [2, 3, 1], [3, 2, 1]]

  """
  @spec drop_permutations(Enum.t(), integer) :: Enum.t()
  def drop_permutations(enum, n) when is_integer(n), do: Permutations.drop(enum, n)

  @doc """
  Returns the nth permutation that `permutations/1` would have returned. `n` is
  zero based, and a negative `n` counts from the end.

  Raises `Enum.OutOfBoundsError` if there is no such permutation.

  ## Examples

      iex> nth_permutation([1, 2, 3], 1)
      [2, 1, 3]

  """
  @spec nth_permutation(Enum.t(), integer) :: list | no_return
  def nth_permutation(enum, n) when is_integer(n), do: Permutations.nth(enum, n)

  @doc """
  Returns the index in the result of what `permutations/1` would return, if
  `permutations/1` was called with `enum` sorted. The index is zero based.

  ## Examples

      iex> permutation_index([1, 3, 2])
      2

      iex> nth_permutation([1, 2, 3], 2)
      [1, 3, 2]

  """
  @spec permutation_index(Enum.t()) :: non_neg_integer
  def permutation_index(enum), do: Permutations.index(enum)

  @doc """
  Returns all selections of `k` elements from `enum`, where each element may
  be selected any number of times. Repeated elements in `enum` are only
  selected once.

  ## Examples

      iex> selections(1..3, 2) |> Enum.to_list
      [[1, 1], [1, 2], [1, 3], [2, 1], [2, 2], [2, 3], [3, 1], [3, 2], [3, 3]]

      iex> selections([1, 1, 2], 2) |> Enum.to_list
      [[1, 1], [1, 2], [2, 1], [2, 2]]

  """
  @spec selections(Enum.t(), non_neg_integer) :: Enum.t()
  def selections(enum, k) when is_integer(k) and k >= 0, do: CartesianProduct.selections(enum, k)

  @doc """
  Returns a list containing all sets possible with any combination of elements
  in `enum`.

  ## Examples

      iex> subsets(1..3) |> Enum.to_list
      [[], [1], [2], [3], [1, 2], [1, 3], [2, 3], [1, 2, 3]]

      iex> subsets([1, 1, 2]) |> Enum.to_list
      [[], [1], [2], [1, 1], [1, 2], [1, 1, 2]]

  """
  @spec subsets(Enum.t()) :: Enum.t()
  def subsets(enum), do: Combinations.subsets(enum)

  @doc """
  Returns the number of elements `subsets/1` would have returned.

  ## Examples

      iex> count_subsets([1, 2, 3])
      8

      iex> count_subsets([1, 1, 2])
      6

  """
  @spec count_subsets(Enum.t()) :: pos_integer
  def count_subsets(enum), do: Combinations.count_subsets(enum)

  @doc """
  Returns the nth subset that `subsets/1` would have returned. `n` is zero
  based, and a negative `n` counts from the end.

  Raises `Enum.OutOfBoundsError` if there is no such subset.

  ## Examples

      iex> nth_subset([1, 2, 3], 4)
      [1, 2]

  """
  @spec nth_subset(Enum.t(), integer) :: list | no_return
  def nth_subset(enum, n) when is_integer(n), do: Combinations.nth_subset(enum, n)
end
