defmodule SComb.Combinations do
  @moduledoc false

  # Combinations of a multiset in colexicographic order, ranking the distinct
  # values by first appearance: by how many copies of the last value they
  # hold, fewest first, then of the value before it, and so on, as in [1, 2],
  # [1, 3], [2, 3], [1, 4]. Consecutive combinations then differ in their first
  # elements, so they are built onto shared tails, most of them with a single
  # new list cell. The multiset is walked from its last value, as a list of
  # entries `{value, count, before}`, where `before` is the number of elements
  # in the entries before it.

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
  def with_replacement(enum, k),
    do: enum |> Enum.uniq() |> Enum.map(&{&1, k}) |> entries() |> generate(k)

  def count_with_replacement(enum, k) do
    distinct = enum |> Enum.uniq() |> length()
    if distinct + k == 0, do: 1, else: Math.binomial(distinct + k - 1, k)
  end

  def nth_with_replacement(enum, k, n) do
    values = Enum.uniq(enum)
    n = Multiset.index!(n, count_with_replacement(values, k))
    values |> Enum.reverse() |> nth_replacing(length(values) - 1, k, n, [])
  end

  # Takes t copies of the last value, fewest first. Each choice of t has as
  # many combinations as there are ways to fill the j = k - t places left with
  # the d values before it, which is C(d + j - 1, j).
  defp nth_replacing(_values, _d, 0, _n, acc), do: acc
  defp nth_replacing([value | _], 0, k, _n, acc), do: Multiset.dup(value, k, acc)

  defp nth_replacing([value | rest], d, k, n, acc) do
    {t, n} = skip_replacing(d, k, 0, Math.binomial(d + k - 1, k), n)
    nth_replacing(rest, d - 1, k - t, n, Multiset.dup(value, t, acc))
  end

  # ways is the number of combinations with t copies. With one more copy
  # there is one place less to fill, C(d + j - 2, j - 1) ways.
  defp skip_replacing(d, k, t, ways, n) do
    if n < ways do
      {t, n}
    else
      j = k - t
      skip_replacing(d, k, t + 1, div(ways * j, d + j - 1), n - ways)
    end
  end

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
      Enum.reduce(multiset, {[], 0}, fn {value, count}, {entries, before} ->
        {[{value, count, before} | entries], before + count}
      end)

    entries
  end

  defp size([{_value, count, before} | _]), do: count + before
  defp size([]), do: 0

  defp generate(entries, k) do
    size = size(entries)

    cond do
      k > size -> []
      few?(entries, k, size) -> eager(entries, k, [], [])
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

  # The combinations are a stream of chunks, each the combinations of the
  # entries left built onto the tail of the values picked after them. An
  # element goes through one stream rather than one for each value picked.
  defp leaves(entries, k, tail) do
    size = size(entries)

    cond do
      k > size ->
        []

      few?(entries, k, size) ->
        [{entries, k, tail}]

      true ->
        Stream.flat_map(choices(entries, k), fn {value, t, rest} ->
          leaves(rest, k - t, Multiset.dup(value, t, tail))
        end)
    end
  end

  defp chunk({entries, k, tail}), do: eager(entries, k, tail, [])

  # The combinations of k elements of the entries, each followed by tail, and
  # then the list acc. The ones with the fewest copies of the last value come
  # first, so they are built last.
  defp eager(_entries, 0, tail, acc), do: [tail | acc]

  defp eager([{value, count, before} | rest], k, tail, acc) when count + before >= k,
    do: copies(value, min(count, k), max(0, k - before), rest, k, tail, acc)

  defp eager(_entries, _k, _tail, acc), do: acc

  # The combinations with t copies of the value, for t down to least
  defp copies(value, t, least, rest, k, tail, acc) when t >= least do
    acc = eager(rest, k - t, Multiset.dup(value, t, tail), acc)
    copies(value, t - 1, least, rest, k, tail, acc)
  end

  defp copies(_value, _t, _least, _rest, _k, _tail, acc), do: acc

  # The ways to pick the last value of a combination, and how many copies, in
  # the order of the combinations: an earlier last value first, then fewer
  # copies first
  defp choices(entries, k), do: choices(entries, k, [])

  defp choices([{value, count, before} | rest], k, acc) when count + before >= k do
    picks = for t <- max(1, k - before)..min(count, k)//1, do: {value, t, rest}
    choices(rest, k, picks ++ acc)
  end

  defp choices(_entries, _k, acc), do: acc

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

  defp nth_k(_multiset, 0, _n), do: []

  defp nth_k(multiset, k, n) do
    if Multiset.distinct?(multiset) do
      values = multiset |> Enum.map(&elem(&1, 0)) |> Enum.reverse()
      c = length(values) - 1
      nth_distinct(values, c, k, n, Math.binomial(c, k), [])
    else
      multiset |> with_counts_before(k) |> nth_multiset(k, n, [])
    end
  end

  # The combinatorial number system: in colexicographic order, the index of a
  # combination of distinct elements is the sum of C(c, i) over its elements,
  # where c is the position of its i-th smallest element. The largest element
  # is then at the last position c with C(c, k) no greater than the index.
  # values are walked from position c down, and b is C(c, k).
  defp nth_distinct(_values, _c, 0, _n, _b, acc), do: acc

  defp nth_distinct([value | values], c, k, n, b, acc) do
    if b <= n do
      # C(c - 1, k - 1) is C(c, k) * k / c
      nth_distinct(values, c - 1, k - 1, n - b, div(b * k, max(c, 1)), [value | acc])
    else
      # C(c - 1, k) is C(c, k) * (c - k) / c
      nth_distinct(values, c - 1, k, n, div(b * (c - k), c), acc)
    end
  end

  # Pairs each entry, from the last, with a tuple of the number of
  # combinations of each size in the entries before it
  defp with_counts_before(multiset, k) do
    {entries, _poly} =
      Enum.reduce(multiset, {[], polynomial([], k)}, fn {value, count}, {entries, poly} ->
        {[{value, count, List.to_tuple(poly)} | entries], multiply(poly, count)}
      end)

    entries
  end

  defp nth_multiset(_entries, 0, _n, acc), do: acc

  defp nth_multiset([{value, count, counts_before} | rest], k, n, acc) do
    {t, n} = skip_copies(counts_before, k, 0, min(count, k), n)
    nth_multiset(rest, k - t, n, Multiset.dup(value, t, acc))
  end

  # Takes t copies of the value, fewest first, each choice followed by the
  # combinations of k - t elements of the entries before it
  defp skip_copies(counts_before, k, t, most, n) do
    block = elem(counts_before, k - t)

    if n < block or t == most,
      do: {t, n},
      else: skip_copies(counts_before, k, t + 1, most, n - block)
  end
end
