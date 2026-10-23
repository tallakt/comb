defmodule SComb.Combinations do
  @moduledoc false

  # Combinations of a multiset in lexicographic order, ranking the distinct
  # values by first appearance. More copies of a value come first, as in
  # [1, 1] before [1, 2]. The multiset is walked as a list of entries
  # `{value, count, later}`, where `later` is the number of elements in the
  # entries that follow.

  alias SComb.{Math, Multiset}

  # Subtrees with at most this many combinations are built as lists, as
  # streams cost more per element
  @eager_limit 2000

  # Counting the combinations exactly, to decide this, is done only when it
  # takes no more than this many steps
  @exact_limit 20_000

  def combinations(enum, k), do: enum |> Multiset.from_enum() |> entries() |> generate(k)

  def subsets(enum) do
    multiset = Multiset.from_enum(enum)
    entries = entries(multiset)
    0..Multiset.size(multiset) |> Stream.flat_map(&generate(entries, &1))
  end

  # Combinations in which a value may be used any number of times are the
  # combinations of the values each there k times
  def with_replacement(enum, k) do
    values = Enum.uniq(enum)
    last = length(values) - 1

    values
    |> Enum.with_index(fn value, i -> {value, k, (last - i) * k} end)
    |> generate(k)
  end

  def count_with_replacement(enum, k) do
    distinct = enum |> Enum.uniq() |> length()
    if distinct + k == 0, do: 1, else: Math.binomial(distinct + k - 1, k)
  end

  def nth_with_replacement(enum, k, n) do
    values = Enum.uniq(enum)
    n = Multiset.index!(n, count_with_replacement(values, k))
    nth_replacing(values, k, n)
  end

  defp nth_replacing(_values, 0, _n), do: []

  # Takes t copies of the first value, the most first. Each choice of t has
  # as many combinations as there are ways to fill the k - t places left with
  # the d values after it, which is C(d + j - 1, j) for j places.
  defp nth_replacing([value | rest], k, n) do
    {t, n} = skip_replacing(length(rest), k, 0, 1, n)
    Multiset.dup(value, t, nth_replacing(rest, k - t, n))
  end

  # Walks j, the number of places left to fill, from 0 up, so t = k - j goes
  # down from k. ways is the number of combinations for j.
  defp skip_replacing(d, k, j, ways, n) do
    if n < ways or j == k do
      {k - j, n}
    else
      skip_replacing(d, k, j + 1, next_ways(d, j, ways), n - ways)
    end
  end

  # C(d + j, j + 1) from C(d + j - 1, j), and no ways to fill places without values
  defp next_ways(0, _j, _ways), do: 0
  defp next_ways(d, j, ways), do: div(ways * (d + j), j + 1)

  def count(enum, k), do: enum |> Multiset.from_enum() |> count_k(k)

  def count_subsets(enum) do
    enum
    |> Multiset.from_enum()
    |> Multiset.counts()
    |> Enum.reduce(1, &(&2 * (&1 + 1)))
  end

  def nth(enum, k, n) do
    multiset = Multiset.from_enum(enum)
    nth_k(multiset, k, Multiset.index!(n, count_k(multiset, k)))
  end

  def nth_subset(enum, n) do
    multiset = Multiset.from_enum(enum)
    size = Multiset.size(multiset)
    counts = counts_by_size(multiset, size)
    n = Multiset.index!(n, Enum.sum(counts))

    {k, n} =
      counts
      |> Enum.with_index()
      |> Enum.reduce_while(n, fn {count, k}, n ->
        if n < count, do: {:halt, {k, n}}, else: {:cont, n - count}
      end)

    nth_k(multiset, k, n)
  end

  defp entries(multiset) do
    {entries, _size} =
      List.foldr(multiset, {[], 0}, fn {value, count}, {entries, later} ->
        {[{value, count, later} | entries], later + count}
      end)

    entries
  end

  defp size([{_value, count, later} | _]), do: count + later
  defp size([]), do: 0

  defp generate(entries, k) do
    size = size(entries)

    cond do
      k > size -> []
      few?(entries, k, size) -> eager(entries, k)
      true -> Stream.flat_map(leaves(entries, k, []), &chunk/1)
    end
  end

  # Whether there are few enough combinations to build them as a list. The
  # binomial is the number of combinations of distinct elements, and an upper
  # bound otherwise, when the number is found exactly if that is cheap.
  defp few?(entries, k, size) do
    Math.binomial(size, k) <= @eager_limit or
      (length(entries) * k <= @exact_limit and
         entries |> Enum.map(&Tuple.delete_at(&1, 2)) |> count_k(k) <= @eager_limit)
  end

  # The combinations are a list of chunks, each the combinations of what is
  # left after the values picked, which are held reversed. An element goes
  # through one stream rather than one for each value picked.
  defp leaves(entries, k, picked) do
    size = size(entries)

    cond do
      k > size ->
        []

      few?(entries, k, size) ->
        [{entries, k, picked}]

      true ->
        Stream.flat_map(choices(entries, k), fn {value, t, rest} ->
          leaves(rest, k - t, Multiset.dup(value, t, picked))
        end)
    end
  end

  defp chunk({entries, k, picked}) do
    case Enum.reverse(picked) do
      [] -> eager(entries, k)
      prefix -> Enum.map(eager(entries, k), &(prefix ++ &1))
    end
  end

  defp eager(entries, k), do: eager(entries, k, [])

  # The combinations of k elements, followed by the list acc. Those with the
  # most copies of the first value come first. Building onto acc rather than
  # joining lists saves copying each combination for each value.
  defp eager(_entries, 0, acc), do: [[] | acc]

  defp eager([{value, count, later} | rest], k, acc) when count + later >= k do
    without = eager(rest, k, acc)

    Enum.reduce(max(1, k - later)..min(count, k)//1, without, fn t, acc ->
      :lists.foldr(&[Multiset.dup(value, t, &1) | &2], acc, eager(rest, k - t, []))
    end)
  end

  defp eager(_entries, _k, acc), do: acc

  # The ways to pick the first value of a combination, and how many copies
  defp choices([{value, count, later} | rest], k) when count + later >= k do
    for(t <- min(count, k)..max(1, k - later)//-1, do: {value, t, rest}) ++ choices(rest, k)
  end

  defp choices(_entries, _k), do: []

  defp count_k(multiset, k) do
    if Multiset.distinct?(multiset) do
      Math.binomial(length(multiset), k)
    else
      multiset |> Multiset.counts() |> polynomial(k) |> List.last()
    end
  end

  defp counts_by_size(multiset, size) do
    if Multiset.distinct?(multiset) do
      Enum.map(0..size, &Math.binomial(size, &1))
    else
      multiset |> Multiset.counts() |> polynomial(size)
    end
  end

  # Coefficient j of the product of (1 + x + ... + x^c) over the counts c is
  # the number of combinations of size j. Returns the coefficients up to k.
  defp polynomial(counts, k),
    do: Enum.reduce(counts, [1 | List.duplicate(0, k)], &multiply(&2, &1))

  # Multiplies by (1 + x + ... + x^count), making each coefficient the sum of
  # itself and the count coefficients before it
  defp multiply(poly, count) do
    shifted = List.duplicate(0, count + 1) ++ poly

    {poly, _sum} =
      Enum.zip(poly, shifted)
      |> Enum.map_reduce(0, fn {add, sub}, sum -> {sum + add - sub, sum + add - sub} end)

    poly
  end

  defp nth_k(multiset, k, n) do
    if Multiset.distinct?(multiset) do
      values = Enum.map(multiset, &elem(&1, 0))
      size = length(values)
      nth_distinct(values, size, k, n, Math.binomial(size, k))
    else
      multiset |> with_counts_after(k) |> nth_multiset(k, n)
    end
  end

  # total is the number of combinations of k elements among the size left
  defp nth_distinct(_values, _size, 0, _n, _total), do: []

  defp nth_distinct([value | values], size, k, n, total) do
    with_value = div(total * k, size)

    if n < with_value,
      do: [value | nth_distinct(values, size - 1, k - 1, n, with_value)],
      else: nth_distinct(values, size - 1, k, n - with_value, total - with_value)
  end

  # Pairs each entry with a tuple of the number of combinations of each size
  # in the entries that follow it
  defp with_counts_after(multiset, k) do
    {entries, _poly} =
      List.foldr(multiset, {[], polynomial([], k)}, fn {value, count}, {entries, poly} ->
        {[{value, count, List.to_tuple(poly)} | entries], multiply(poly, count)}
      end)

    entries
  end

  defp nth_multiset(_entries, 0, _n), do: []

  defp nth_multiset([{value, count, counts_after} | rest], k, n) do
    taken =
      Enum.reduce_while(min(count, k)..1//-1, n, fn t, n ->
        block = elem(counts_after, k - t)
        if n < block, do: {:halt, {t, n}}, else: {:cont, n - block}
      end)

    case taken do
      {t, n} -> Multiset.dup(value, t, nth_multiset(rest, k - t, n))
      n -> nth_multiset(rest, k, n)
    end
  end
end
