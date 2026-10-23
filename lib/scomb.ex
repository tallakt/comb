defmodule SComb do
  # The README's examples run as doctests: drop the code fences around them,
  # and the CI badge
  @external_resource "README.md"
  @moduledoc File.read!("README.md")
             |> String.split("\n")
             |> Enum.reject(&String.match?(&1, ~r/```|actions\/workflows/))
             |> Enum.join("\n")

  alias SComb.{CartesianProduct, Combinations, Partitions, Permutations, Sequence}

  # Sequences of inputs up to this many elements, and partitions up to this
  # many, are indexed. See `SComb.Sequence`.
  @index_limit 2000
  @partitions_index_limit 200

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
  Returns any combination of the elements in `enum` with exactly `k` elements,
  as a lazy `SComb.Sequence`. Repeated elements are handled intelligently.

  ## Examples

      iex> combinations([1, 2, 3], 2) |> Enum.to_list
      [[1, 2], [1, 3], [2, 3]]

      iex> combinations([1, 1, 2], 2) |> Enum.to_list
      [[1, 1], [1, 2]]

  """
  @spec combinations(Enum.t(), non_neg_integer) :: Sequence.t()
  def combinations(enum, k) when is_integer(k) and k >= 0 do
    list = Enum.to_list(enum)

    Sequence.new(
      "combinations",
      Combinations.combinations(list, k),
      fn -> Combinations.count(list, k) end,
      &Combinations.nth(list, k, &1),
      indexable: length(list) <= @index_limit
    )
  end

  @doc """
  Returns the combinations of `k` elements of `enum` in which an element may be
  used any number of times, as long as it is in `enum`. Repeated elements in
  `enum` are one element.

  ## Examples

      iex> combinations_with_replacement([1, 2, 3], 2) |> Enum.to_list
      [[1, 1], [1, 2], [1, 3], [2, 2], [2, 3], [3, 3]]

      iex> combinations_with_replacement([1, 1, 2], 2) |> Enum.to_list
      [[1, 1], [1, 2], [2, 2]]

  """
  @spec combinations_with_replacement(Enum.t(), non_neg_integer) :: Sequence.t()
  def combinations_with_replacement(enum, k) when is_integer(k) and k >= 0 do
    list = Enum.to_list(enum)

    Sequence.new(
      "combinations_with_replacement",
      Combinations.with_replacement(list, k),
      fn -> Combinations.count_with_replacement(list, k) end,
      &Combinations.nth_with_replacement(list, k, &1),
      indexable: length(list) * k <= @index_limit
    )
  end

  @doc """
  Returns the number of elements `combinations_with_replacement/2` would have
  returned.

  ## Examples

      iex> count_combinations_with_replacement([1, 2, 3], 2)
      6

  """
  @spec count_combinations_with_replacement(Enum.t(), non_neg_integer) :: non_neg_integer
  def count_combinations_with_replacement(enum, k) when is_integer(k) and k >= 0,
    do: Combinations.count_with_replacement(enum, k)

  @doc """
  Returns the nth combination that `combinations_with_replacement/2` would have
  returned. `n` is zero based, and a negative `n` counts from the end.

  Raises `Enum.OutOfBoundsError` if there is no such combination.

  ## Examples

      iex> nth_combination_with_replacement([1, 2, 3], 2, 4)
      [2, 3]

  """
  @spec nth_combination_with_replacement(Enum.t(), non_neg_integer, integer) ::
          list | no_return
  def nth_combination_with_replacement(enum, k, n)
      when is_integer(k) and k >= 0 and is_integer(n),
      do: Combinations.nth_with_replacement(enum, k, n)

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
  Partitions `enum` into any groups in sum containing all elements, as a lazy
  `SComb.Sequence`. With the `:min` or `:max` option the result is a stream.

  ## Examples

      iex> partitions(1..2) |> Enum.to_list
      [[[1, 2]], [[1], [2]]]

      iex> partitions([1, 1, 2]) |> Enum.to_list
      [[[1, 1, 2]], [[1, 1], [2]], [[1, 2], [1]], [[1], [1], [2]]]

      iex> partitions(1..3, min: 2, max: 2) |> Enum.to_list
      [[[1, 2], [3]], [[1, 3], [2]], [[1], [2, 3]]]

  ## Options

    * `:min` - only return partitions with at least this many blocks
    * `:max` - only return partitions with at most this many blocks

  """
  @spec partitions(Enum.t(), keyword) :: Sequence.t() | Enum.t()
  def partitions(enum, opts \\ []) do
    min = Keyword.get(opts, :min)
    max = Keyword.get(opts, :max)

    if is_nil(min) and is_nil(max) do
      list = Enum.to_list(enum)

      Sequence.new(
        "partitions",
        Partitions.partitions(list),
        fn -> Partitions.count(list) end,
        &Partitions.nth(list, &1),
        indexable: length(list) <= @partitions_index_limit
      )
    else
      Partitions.partitions(enum, min || 0, max || :infinity)
    end
  end

  @doc """
  Returns the number of elements `partitions/1` would have returned. For
  distinct elements this is the Bell number. With repeated elements the
  partitions are counted without generating them, which takes longer the more
  distinct values and repeats there are.

  ## Examples

      iex> count_partitions(1..3)
      5

      iex> count_partitions([1, 1, 2])
      4

      iex> count_partitions(1..30)
      846749014511809332450147

  """
  @spec count_partitions(Enum.t()) :: pos_integer
  def count_partitions(enum), do: Partitions.count(enum)

  @doc """
  Returns the nth partition that `partitions/1` would have returned. `n` is zero
  based, and a negative `n` counts from the end.

  Raises `Enum.OutOfBoundsError` if there is no such partition.

  ## Examples

      iex> nth_partition(1..3, 1)
      [[1, 2], [3]]

      iex> nth_partition([1, 1, 2], -1)
      [[1], [1], [2]]

  """
  @spec nth_partition(Enum.t(), integer) :: [list] | no_return
  def nth_partition(enum, n) when is_integer(n), do: Partitions.nth(enum, n)

  @doc """
  Returns a stream of every permutation of every combination of `k` elements
  of `enum`: all the ways of picking `k` elements in a particular order.
  Repeated elements are handled sensibly.

  ## Examples

      iex> permuted_combinations(1..3, 2) |> Enum.to_list
      [[1, 2], [2, 1], [1, 3], [3, 1], [2, 3], [3, 2]]

      iex> permuted_combinations([1, 1, 2], 2) |> Enum.to_list
      [[1, 1], [1, 2], [2, 1]]

  """
  @spec permuted_combinations(Enum.t(), non_neg_integer) :: Enum.t()
  def permuted_combinations(enum, k) when is_integer(k) and k >= 0,
    do: enum |> combinations(k) |> Stream.flat_map(&permutations/1)

  @doc """
  Returns a lazy `SComb.Sequence` containing all permutations of the input `enum`. A
  permutation will contain all elements in a different order. Repeated elements
  are handled sensibly.

  ## Examples

      iex> permutations(1..3) |> Enum.to_list
      [[1, 2, 3], [2, 1, 3], [1, 3, 2], [3, 1, 2], [2, 3, 1], [3, 2, 1]]

      iex> permutations([1, 1, 2]) |> Enum.to_list
      [[1, 1, 2], [1, 2, 1], [2, 1, 1]]

  """
  @spec permutations(Enum.t()) :: Sequence.t()
  def permutations(enum) do
    list = Enum.to_list(enum)

    Sequence.new(
      "permutations",
      Permutations.permutations(list),
      fn -> Permutations.count(list) end,
      &Permutations.nth(list, &1),
      from: &Permutations.drop(list, &1),
      indexable: length(list) <= @index_limit
    )
  end

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
  Returns all selections of `k` elements from `enum`, as a lazy
  `SComb.Sequence`, where each element may be selected any number of times.
  Repeated elements in `enum` are only selected once.

  ## Examples

      iex> selections(1..3, 2) |> Enum.to_list
      [[1, 1], [1, 2], [1, 3], [2, 1], [2, 2], [2, 3], [3, 1], [3, 2], [3, 3]]

      iex> selections([1, 1, 2], 2) |> Enum.to_list
      [[1, 1], [1, 2], [2, 1], [2, 2]]

  """
  @spec selections(Enum.t(), non_neg_integer) :: Sequence.t()
  def selections(enum, k) when is_integer(k) and k >= 0 do
    list = Enum.to_list(enum)

    Sequence.new(
      "selections",
      CartesianProduct.selections(list, k),
      fn -> CartesianProduct.count_selections(list, k) end,
      &CartesianProduct.nth_selection(list, k, &1),
      indexable: k <= @index_limit
    )
  end

  @doc """
  Returns the number of elements `selections/2` would have returned.

  ## Examples

      iex> count_selections(1..3, 2)
      9

      iex> count_selections([1, 1, 2], 2)
      4

  """
  @spec count_selections(Enum.t(), non_neg_integer) :: non_neg_integer
  def count_selections(enum, k) when is_integer(k) and k >= 0,
    do: CartesianProduct.count_selections(enum, k)

  @doc """
  Returns the nth selection that `selections/2` would have returned. `n` is zero
  based, and a negative `n` counts from the end.

  Raises `Enum.OutOfBoundsError` if there is no such selection.

  ## Examples

      iex> nth_selection(1..3, 2, 4)
      [2, 2]

  """
  @spec nth_selection(Enum.t(), non_neg_integer, integer) :: list | no_return
  def nth_selection(enum, k, n) when is_integer(k) and k >= 0 and is_integer(n),
    do: CartesianProduct.nth_selection(enum, k, n)

  @doc """
  Returns a lazy `SComb.Sequence` containing all sets possible with any
  combination of elements in `enum`.

  ## Examples

      iex> subsets(1..3) |> Enum.to_list
      [[], [1], [2], [3], [1, 2], [1, 3], [2, 3], [1, 2, 3]]

      iex> subsets([1, 1, 2]) |> Enum.to_list
      [[], [1], [2], [1, 1], [1, 2], [1, 1, 2]]

  """
  @spec subsets(Enum.t()) :: Sequence.t()
  def subsets(enum) do
    list = Enum.to_list(enum)

    Sequence.new(
      "subsets",
      Combinations.subsets(list),
      fn -> Combinations.count_subsets(list) end,
      &Combinations.nth_subset(list, &1),
      indexable: length(list) <= @index_limit
    )
  end

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
