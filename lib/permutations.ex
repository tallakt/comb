defmodule Permutations do


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
      max = {{_, max_number, _}, _} = 
        state 
        |> Enum.with_index 
        |> Enum.max_by(&max_value_for/1)
      last = Enum.count(state) - 1
      penultimate = last - 1
      {new_state, new_pos} = 
        case max do
          {{:z, _, _}, _} ->
            {nil, -1}

          {{:-, n, el}, 1} -> # left end, move, and reset direction
            {swap_and_replace_left(state, 1, {:z, n, el}), 0}

          {{:+, n, el}, ^penultimate} -> # left end, move, and reset direction
            {swap_and_replace_right(state, penultimate, {:z, n, el}), last}

          {state_el = {:-, n, el}, pos} ->
            case Enum.fetch!(state, pos - 2) do
              {_, other_n, _} when other_n > n ->
                {swap_and_replace_left(state, pos, {:z, n, el}), pos - 1}

              _ ->
                {swap_and_replace_left(state, pos, state_el), pos - 1}
              end

          {state_el = {:+, n, el}, pos} ->
            case Enum.fetch!(state, pos + 2) do
              {_, other_n, _} when other_n > n ->
                {swap_and_replace_right(state, pos, {:z, n, el}), pos + 1}

              _ ->
                {swap_and_replace_right(state, pos, state_el), pos + 1}
            end
        end
      update_signs_for_larger(new_state, new_pos, max_number)
    end

    defp update_signs_for_larger(nil, _, _), do: nil

    defp update_signs_for_larger(new_state, new_pos, max_number) do
      {result, _} =
        new_state
        |> Enum.reduce({[], 0}, fn
            {_, n, el}, {res, i} when n > max_number and i < new_pos ->
              res = [{:+, n, el} | res]
              {res, i + 1}

            {_, n, el}, {res, i} when n > max_number and i > new_pos ->
              res = [{:-, n, el} | res]
              {res, i + 1}

            state_el, {res, i} ->
              res = [state_el | res]
              {res, i + 1}
          end)
      result |> :lists.reverse
    end


    defp swap_and_replace_left(list, pos, a) do
      do_swap_and_replace_left list, pos, a, []
    end

    defp do_swap_and_replace_left([h|t], pos, a, acc) when pos > 0 do
      do_swap_and_replace_left t, pos - 1, a, [h|acc]
    end

    defp do_swap_and_replace_left([_|t], _, a, [acc_h|acc_t]) do
      put_reverse_in_front(acc_t, [a, acc_h | t])
    end

    defp swap_and_replace_right(list, pos, a) do
      do_swap_and_replace_right list, pos, a, []
    end

    defp do_swap_and_replace_right([h|t], pos, a, acc) when pos > 0 do
      do_swap_and_replace_right t, pos - 1, a, [h|acc]
    end

    defp do_swap_and_replace_right([_, b | t], _, a, acc) do
      put_reverse_in_front(acc, [b, a | t])
    end

    defp put_reverse_in_front([], list), do: list
    defp put_reverse_in_front([h|t], list), do: put_reverse_in_front(t, [h|list])

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
      |> Enum.with_index
      |> Enum.map(fn {a, b} -> {b, a} end)
      |> Stream.unfold fn
        [] -> nil
        p -> {result_for(p), next_permutation(p)}
      end
    end

    defp result_for(permutation) do
      Enum.map(permutation, &(elem(&1, 1)))
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
