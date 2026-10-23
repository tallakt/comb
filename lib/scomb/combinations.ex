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

  def combinations(enum, k), do: enum |> Multiset.from_enum() |> entries() |> generate(k)

  def subsets(enum) do
    multiset = Multiset.from_enum(enum)
    entries = entries(multiset)
    0..Multiset.size(multiset) |> Stream.flat_map(&generate(entries, &1))
  end

  # A combination in which a value may be used any number of times starts with
  # the first value, followed by one with k - 1 values, or has no copy of it
  def with_replacement(enum, k), do: enum |> Enum.uniq() |> replacing(k)

  defp replacing(_values, 0), do: [[]]
  defp replacing([], _k), do: []

  defp replacing([value | rest] = values, k) do
    if Math.binomial(length(values) + k - 1, k) <= @eager_limit do
      for(tail <- replacing(values, k - 1), do: [value | tail]) ++ replacing(rest, k)
    else
      Stream.flat_map([:with, :without], fn
        :with -> Stream.map(replacing(values, k - 1), &[value | &1])
        :without -> replacing(rest, k)
      end)
    end
  end

  # Combinations in which a value may be used any number of times are also the
  # combinations of the values each repeated k times, which is how nth finds
  # them

  def count_with_replacement(enum, k) do
    distinct = enum |> Enum.uniq() |> length()
    if distinct + k == 0, do: 1, else: Math.binomial(distinct + k - 1, k)
  end

  def nth_with_replacement(enum, k, n), do: enum |> repeat(k) |> nth(k, n)

  defp repeat(enum, k), do: enum |> Enum.uniq() |> Enum.flat_map(&List.duplicate(&1, k))

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
      Math.binomial(size, k) <= @eager_limit -> eager(entries, k)
      true -> lazy(entries, k)
    end
  end

  defp eager(_entries, 0), do: [[]]

  defp eager([{value, count, later} | rest], k) when count + later >= k do
    with_value =
      for t <- min(count, k)..max(1, k - later)//-1,
          tail <- eager(rest, k - t),
          do: Multiset.dup(value, t, tail)

    with_value ++ eager(rest, k)
  end

  defp eager(_entries, _k), do: []

  defp lazy(entries, k) do
    entries
    |> choices(k)
    |> Stream.flat_map(fn {value, t, rest} ->
      case generate(rest, k - t) do
        tails when is_list(tails) -> Enum.map(tails, &Multiset.dup(value, t, &1))
        tails -> Stream.map(tails, &Multiset.dup(value, t, &1))
      end
    end)
  end

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
