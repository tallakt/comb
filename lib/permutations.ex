defmodule Permutations do
  defmodule TallakStream do
    @doc """
    Returns a stream of all permutations of the given collection.

    The count parameter will limit the number of elements, all are returned
    by default

    ## Examples

        iex> permutation([1, 2, 3]) |> Enum.sort
        [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]
        
    """
    def permutation(enumerable, count) when count >= 0 do
      enumerable |> Enum.to_list |> do_permutation(count)
    end

    def permutation(enumerable) do
      enumerable |> Enum.to_list |> do_permutation(-1)
    end

    defp do_permutation([], _), do: []

    defp do_permutation(_, 0), do: []

    defp do_permutation(list, count) do
      list
      |> elements_partitioned
      |> Stream.flat_map(fn {element, the_rest} ->
        case {count, the_rest} do
        {_, []} ->
          [[element]]
        {1, _} ->
          [[element]]
        _ ->
          the_rest |> do_permutation(count - 1) |> Stream.map(fn p -> [element | p] end)
        end
      end)
    end

    defp elements_partitioned(enumerable) do
      enumerable
      |> Stream.map fn element -> 
        other = enumerable |> Enum.reject(fn x -> x == element end)
        {element, other}
      end
    end
  end

  defmodule TallakEnum do
    @doc """
    Returns a stream of all permutations of the given collection.

    ## Examples

        iex> permutation([1, 2, 3]) |> Enum.sort
        [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]

    """
    def permutation(enumerable, count) when count >= 0 do
      enumerable |> Enum.to_list |> do_permutation(count)
    end

    def permutation(enumerable) do
      enumerable |> Enum.to_list |> do_permutation(-1)
    end

    defp do_permutation([], _), do: []
    defp do_permutation(_, 0), do: []

    defp do_permutation(list, count) do
      list
      |> elements_partitioned
      |> Enum.flat_map(fn {element, the_rest} ->
        case {count, the_rest} do
        {_, []} ->
          [[element]]
        {1, _} ->
          [[element]]
        _ ->
          the_rest 
          |> do_permutation(count - 1) 
          |> Enum.map(fn p -> [element | p] end)
        end
      end)
    end

    defp elements_partitioned(enumerable) do
      enumerable
      |> Enum.map fn element -> 
          other = enumerable |> Enum.reject(fn x -> x == element end)
          {element, other}
        end
    end
  end

  defmodule Naive do
    @doc """

    ## Examples

        iex> permutation([1, 2, 3]) |> Enum.sort
        [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]

    """
    def permutation([]), do: [[]]

    def permutation(list) when is_list(list) do
      for h <- list, t <- permutation(list -- [h]), do: [h | t]
    end

    def permutation(enum), do: permutation(Enum.to_list(enum))
  end

  # slack @martinsvalin
  defmodule LazyPermutations  do
    @doc """

    ## Examples

        iex> permutation([1, 2, 3]) |> Enum.sort
        [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]

    """
    def permutation(list) do
      list
      |> Enum.sort
      |> Stream.unfold fn
        [] -> nil
        p -> {p, next_permutation(p)}
      end
    end

    defp next_permutation(permutation) do
      if permutation == permutation |> Enum.sort |> Enum.reverse do
        []
      else
        permutation
        |> split
        |> heal
      end
    end

    defp split(permutation) do
      permutation
      |> Enum.reverse
      |> Enum.reduce({0, false, [], []}, fn(x, {prev, split, first, last}) ->
        case split do
          false -> {x, x < prev, first, [x|last]}
          true -> {x, true, [x|first], last}
        end
      end)
      |> fn({_, _,first, last}) -> {first, last} end.()
    end

    defp heal({first, [h|_] = last}) do
      next = last |> Enum.filter(&(&1 > h)) |> Enum.min
      rest = last -- [next] |> Enum.sort
      first ++ [next] ++ rest
    end
  end

  defmodule Wless1 do
    @doc """

    ## Examples

        iex> combinations([1, 2, 3], 2) |> Enum.sort
        [[1, 2], [1, 3], [2, 3]]

    """
    def combinations(collection, k) do
      List.last(do_combinations(collection, k))
    end

    defp do_combinations(list, k) do
      combinations_by_length = [[[]]|List.duplicate([], k)]

      List.foldr list, combinations_by_length, fn x, next ->
        sub = :lists.droplast(next)
        step = [[]|(for l <- sub, do: (for s <- l, do: [x|s]))]
        :lists.zipwith(&:lists.append/2, step, next)
      end
    end

    def combinations2(_, 0), do: [[]]
    def combinations2([], _), do: []
    def combinations2([h|t], k) do
      (for l <- combinations2(t, k - 1), do: [h|l]) ++ combinations2(t, k)
    end
  end
end
