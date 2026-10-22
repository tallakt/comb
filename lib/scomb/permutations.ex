defmodule SComb.Permutations do
  @moduledoc false

  # Each distinct value gets a key, the value appearing last in the input
  # getting key 0. Read backwards, the permutations are in lexicographic order
  # of their keys, so the classic next permutation algorithm applies, working
  # from the head of the list. A permutation is held as a list of keys and a
  # list of values, and consecutive permutations share their tails.

  alias SComb.{Math, Multiset}

  # The first permutation has the repeated elements grouped, in order of first
  # appearance
  def permutations(enum) do
    multiset = Multiset.from_enum(enum)
    d = length(multiset)

    keys =
      multiset
      |> Enum.with_index(fn {_value, count}, i -> List.duplicate(d - 1 - i, count) end)
      |> Enum.concat()

    values = Enum.flat_map(multiset, fn {value, count} -> List.duplicate(value, count) end)

    stream({keys, values})
  end

  def count(enum), do: enum |> Multiset.from_enum() |> Multiset.counts() |> Math.multinomial()

  def drop(enum, n) when n >= 0 do
    multiset = Multiset.from_enum(enum)
    total = multiset |> Multiset.counts() |> Math.multinomial()

    if n < total, do: multiset |> unrank(total, n) |> stream(), else: []
  end

  # Like Stream.drop/2, a negative n drops from the end
  def drop(enum, n), do: enum |> permutations() |> Stream.drop(n)

  def nth(enum, n) do
    multiset = Multiset.from_enum(enum)
    total = multiset |> Multiset.counts() |> Math.multinomial()
    i = if n < 0, do: total + n, else: n

    if i < 0 or i >= total, do: raise(Enum.OutOfBoundsError, index: n)

    {_keys, values} = unrank(multiset, total, i)
    values
  end

  def index(enum) do
    list = Enum.to_list(enum)
    multiset = list |> Enum.sort() |> Multiset.from_enum()
    total = multiset |> Multiset.counts() |> Math.multinomial()

    list
    |> Enum.reverse()
    |> rank(Enum.reverse(multiset), length(list), total, 0)
  end

  defp stream(state) do
    Stream.unfold(state, fn
      nil -> nil
      {_keys, values} = state -> {values, next(state)}
    end)
  end

  defp next({[k | keys], [v | values]}), do: next(keys, values, k, [k], [v])
  defp next({[], []}), do: nil

  # Walks the non-decreasing head, keeping it reversed. The first key smaller
  # than its predecessor is the pivot.
  defp next([k | keys], [v | values], prev, head_k, head_v) when k >= prev,
    do: next(keys, values, k, [k | head_k], [v | head_v])

  defp next([k | keys], [v | values], _prev, head_k, head_v),
    do: swap(head_k, head_v, k, v, keys, values)

  defp next([], [], _prev, _head_k, _head_v), do: nil

  # Swaps the pivot with the smallest larger key of the head. The reversed
  # head then becomes the new head, as the algorithm reverses it anyway.
  defp swap([a, b | head_k], [x, y | head_v], k, v, keys, values) when b > k do
    {keys, values} = swap([b | head_k], [y | head_v], k, v, keys, values)
    {[a | keys], [x | values]}
  end

  defp swap([a | head_k], [x | head_v], k, v, keys, values),
    do: {[k | head_k] ++ [a | keys], [v | head_v] ++ [x | values]}

  # The nth permutation is built from its last element backwards. Each
  # candidate value, in order of increasing key, is followed by a block of
  # total * count / size permutations.
  defp unrank(multiset, total, n) do
    multiset
    |> Enum.reverse()
    |> Enum.with_index(fn {value, count}, key -> {key, value, count} end)
    |> unrank(Multiset.size(multiset), total, n, [], [])
  end

  defp unrank([], _size, _total, _n, keys, values), do: {keys, values}

  defp unrank(candidates, size, total, n, keys, values) do
    {key, value, n, total, candidates} = pick(candidates, size, total, n)
    unrank(candidates, size - 1, total, n, [key | keys], [value | values])
  end

  defp pick([{key, value, count} = candidate | candidates], size, total, n) do
    block = div(total * count, size)

    cond do
      n >= block ->
        {k, v, n, total, candidates} = pick(candidates, size, total, n - block)
        {k, v, n, total, [candidate | candidates]}

      count == 1 ->
        {key, value, n, block, candidates}

      true ->
        {key, value, n, block, [{key, value, count - 1} | candidates]}
    end
  end

  # The reverse of unrank/3, summing the blocks skipped at each element
  defp rank([], _candidates, _size, _total, acc), do: acc

  defp rank([x | rest], candidates, size, total, acc) do
    {skipped, total, candidates} = skip_to(candidates, x, size, total)
    rank(rest, candidates, size - 1, total, acc + skipped)
  end

  defp skip_to([{value, count} = candidate | candidates], x, size, total) do
    block = div(total * count, size)

    cond do
      value !== x ->
        {skipped, total, candidates} = skip_to(candidates, x, size, total)
        {skipped + block, total, [candidate | candidates]}

      count == 1 ->
        {0, block, candidates}

      true ->
        {0, block, [{value, count - 1} | candidates]}
    end
  end
end
