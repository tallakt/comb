defmodule Permutations do
  defmodule TallakMaps do
    @doc """
    Returns a stream of all permutations of the given collection.

    The count parameter will limit the number of elements, all are returned
    by default

    ## Examples

        iex> permutation([1, 2, 3]) |> Enum.sort
        [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]
        
    """
    def permutation(enum) do
      element_map = for {e,i} <- Enum.with_index(enum), into: %{}, do: {i, e}
      last = Enum.count(element_map) - 1
      initial_order = for i <- 0..last, into: %{}, do: {i, i}
      stream_permutations(last, initial_order)
      |> Stream.map(fn order ->
          Enum.map(0..last,
            &(Map.fetch!(element_map, Map.fetch!(order, &1)))
          )
        end)
    end

    defp stream_permutations(0, initial_order) do
      [initial_order]
    end

    defp stream_permutations(last, initial_order) do
      last_in_order = Map.fetch! initial_order, last

      last..0
      |> Stream.flat_map(fn i ->
          case i do
            ^last ->
              stream_permutations(last - 1, initial_order)
            _ ->
              order =
                initial_order # swap last and i
                |> Map.put(last, Map.fetch!(initial_order, i))
                |> Map.put(i, last_in_order)
              stream_permutations(last - 1, order)
          end
        end)
    end
  end


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

  defmodule SJT do
    @doc """

    ## Examples

        iex> permutation([1, 2, 3]) |> Enum.sort
        [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]

    """
    def permutation([]), do: [[]]

    def permutation(enum) do
      state = 
        for {e, i} <- Enum.with_index(enum),
          do: {initial_direction_for(i), i, e}
      Stream.unfold(state, &do_permutation/1)
    end

    defp initial_direction_for(0), do: :z
    defp initial_direction_for(_), do: :-

    defp advance(state) do
      max = state |> Enum.with_index |> Enum.max_by(&max_value_for/1)
      penultimate = Enum.count(state) - 2
      case max do
        {{:z, _, _}, _} ->
          nil

        {{:-, n, el}, 1} -> # left end, move, and reset direction
          state
          |> List.delete_at(1)
          |> List.insert_at(0, {:z, n, el})

        {{:+, n, el}, ^penultimate} -> # left end, move, and reset direction
          state
          |> :lists.reverse
          |> List.delete_at(1)
          |> List.insert_at(0, {:z, n, el})
          |> :lists.reverse

        {state_el = {:-, n, el}, pos} ->
          case Enum.fetch!(state, pos - 2) do
            {_, other_n, _} when other_n > n ->
              state
              |> List.delete_at(pos)
              |> List.insert_at(pos - 1, {:z, n, el})
              |> List.update_at(pos - 2, fn {_, a, b} -> {:+, a, b} end)

            _ ->
              state
              |> List.delete_at(pos)
              |> List.insert_at(pos - 1, state_el)
          end

        {state_el = {:+, n, el}, pos} ->
          case Enum.fetch!(state, pos + 2) do
            {_, other_n, _} when other_n > n ->
              state
              |> List.delete_at(pos)
              |> List.insert_at(pos + 1, {:z, n, el})
              |> List.update_at(pos + 2, fn {_, a, b} -> {:-, a, b} end)

            _ ->
              state
              |> List.delete_at(pos)
              |> List.insert_at(pos + 1, state_el)
          end
      end
    end


    defp do_permutation(nil), do: nil

    defp do_permutation(state) do
      result = state |> Enum.map(fn {_, _, el} -> el end)
      {result, advance(state)}
    end

    defp max_value_for({{:z, _, _}, _}), do: -1
    defp max_value_for({{_, i, _}, _}), do: i

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

    @doc """
    Naive implementation

    ## Examples

        iex> combinations2([1, 2, 3], 2) |> Enum.sort
        [[1, 2], [1, 3], [2, 3]]

    """
    def combinations2(_, 0), do: [[]]
    def combinations2([], _), do: []
    def combinations2([h|t], k) do
      (for l <- combinations2(t, k - 1), do: [h|l]) ++ combinations2(t, k)
    end
  end
end
