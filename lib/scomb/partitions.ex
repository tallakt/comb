defmodule SComb.Partitions do
  @moduledoc false

  # A partition is a list of blocks. With the distinct values ranked by first
  # appearance, each block is described by how many of each value it holds.
  # Keeping the blocks in non-increasing lexicographic order of these counts
  # gives every partition of a multiset exactly one form, so no duplicates are
  # generated. The first block always holds the first value left, and the
  # blocks are generated largest first.
  #
  # The values left are held as entries `{rank, value, count}`, and a block's
  # counts as `{rank, count}` for the values it holds.

  alias SComb.{Math, Multiset}

  # Partitions of at most this many elements are built as lists, as streams
  # cost more per element
  @eager_size 8

  # The most combinations of the counts of repeated elements for which a plan
  # is made when a sequence is created
  @cheap_plan 3000

  # The number of blocks may be limited to min..max. The limits are held as
  # `{used, min, max}`, where used is the number of blocks already placed.
  # The max may be :infinity, as every number is smaller than an atom.
  def partitions(enum, min \\ 0, max \\ :infinity) do
    multiset = Multiset.from_enum(enum)

    multiset
    |> Enum.with_index(fn {value, count}, rank -> {rank, value, count} end)
    |> generate(:free, Multiset.size(multiset), {0, min, max})
  end

  # The partitions of the entries with no block greater than bound
  defp generate([], _bound, _size, {used, min, max}),
    do: if(used >= min and used <= max, do: [[]], else: [])

  defp generate(entries, bound, size, {used, min, max} = limits) do
    # The most elements the next block may hold while the rest, one to a
    # block, can still reach the min number of blocks
    slack = size + used + 1 - min

    if used >= max or slack < 1 do
      []
    else
      # The last block allowed has to take all that is left
      all? = used + 1 == max
      fill(entries, bound, 1, [], [], [], size, put_elem(limits, 0, used + 1), {slack, all?})
    end
  end

  # Decides how many copies of each entry go in the next block, largest first,
  # then partitions what is left. The block and what is left are built
  # reversed. bound holds the counts of the previous block not yet passed, or
  # is :free once the block is smaller.
  defp fill(
         [{rank, value, count} | entries],
         bound,
         min,
         values,
         counts,
         left,
         size,
         limits,
         room
       ) do
    {slack, all?} = room

    bound
    |> choices(rank, count, min)
    |> Enum.filter(fn {t, _bound} -> t <= slack and (not all? or t == count) end)
    |> flat_map(size > @eager_size, fn {t, bound} ->
      values = Multiset.dup(value, t, values)
      counts = if t > 0, do: [{rank, t} | counts], else: counts
      left = if t < count, do: [{rank, value, count - t} | left], else: left
      fill(entries, bound, 0, values, counts, left, size - t, limits, {slack - t, all?})
    end)
  end

  defp fill([], _bound, _min, values, counts, left, size, limits, _room) do
    block = Enum.reverse(values)

    left
    |> Enum.reverse()
    |> generate(Enum.reverse(counts), size, limits)
    |> map(size > @eager_size, &[block | &1])
  end

  # Counting and ranking. The first blocks a partition of the entries may have
  # are the same as the ones generate/4 tries, in the same order. The number of
  # partitions after a first block depends only on what is left and the block,
  # so it is looked up in a memo when seen before.

  # The numbers needed to count and rank the partitions of an input. Finding
  # them takes the time of a count, so a sequence keeps the plan to count and
  # find any number of partitions. With distinct elements it holds the Bell
  # numbers, otherwise the entries and the memo of the counts.
  def plan(enum) do
    multiset = Multiset.from_enum(enum)

    if Multiset.distinct?(multiset) do
      {:distinct, Enum.map(multiset, &elem(&1, 0)), multiset |> length() |> bells()}
    else
      entries = entries(multiset)
      {count, memo} = count_blocks(entries, :free, %{})
      {:memo, entries, count, memo}
    end
  end

  # Whether the plan for the input is quick to find: it has no more than a
  # few distinct combinations of repeated elements to count
  def cheap?(enum) do
    multiset = Multiset.from_enum(enum)

    Multiset.distinct?(multiset) or
      multiset |> Multiset.counts() |> Enum.reduce(1, &(&2 * (&1 + 1))) <= @cheap_plan
  end

  def count(enum), do: enum |> plan() |> plan_count()

  def plan_count({:distinct, _values, bells}), do: last(bells)
  def plan_count({:memo, _entries, count, _memo}), do: count

  def nth(enum, n), do: enum |> plan() |> nth_plan(n)

  def nth_plan({:distinct, values, bells}, n),
    do: nth_distinct(values, Multiset.index!(n, last(bells)), bells)

  def nth_plan({:memo, entries, count, memo}, n) do
    unrank(entries, :free, Multiset.index!(n, count), memo)
  end

  defp entries(multiset), do: Enum.with_index(multiset, fn {v, c}, rank -> {rank, v, c} end)

  # The memo holds for each state the number of partitions, and the number
  # after each of its first blocks. The states are found by their shape, so
  # the blocks themselves are not kept: other values may have the same shape.
  defp count_blocks([], _bound, memo), do: {1, memo}

  defp count_blocks(entries, bound, memo) do
    key = memo_key(entries, bound)

    case memo do
      %{^key => {count, _counts}} ->
        {count, memo}

      %{} ->
        {counts, memo} =
          entries
          |> first_blocks(bound)
          |> Enum.map_reduce(memo, fn {_block, left, bound}, memo ->
            count_blocks(left, bound, memo)
          end)

        count = Enum.sum(counts)
        {count, Map.put(memo, key, {count, counts})}
    end
  end

  defp unrank([], _bound, _n, _memo), do: []

  defp unrank(entries, bound, n, memo) do
    key = memo_key(entries, bound)
    %{^key => {_count, counts}} = memo
    {block, left, bound, n} = find_block(first_blocks(entries, bound), counts, n)
    [block | unrank(left, bound, n, memo)]
  end

  defp find_block([{block, left, bound} | blocks], [count | counts], n) do
    if n < count, do: {block, left, bound, n}, else: find_block(blocks, counts, n - count)
  end

  # What is left and the bound decide how many partitions there are, whatever
  # the values are. The ranks are numbered again so that entries with the same
  # counts have the same key. The bound is :free if it starts at a rank before
  # the first entry, as a block starting there is smaller.
  defp memo_key([{first, _value, _count} | _] = entries, bound) do
    if bound == :free or match?([{rank, _} | _] when rank < first, bound) do
      # Only the counts decide, as the order of the ranks is that of the entries
      {Enum.map(entries, &elem(&1, 2)), :free}
    else
      ranks = Enum.map(entries, &elem(&1, 0)) ++ Enum.map(bound, &elem(&1, 0))
      index = ranks |> Enum.sort() |> Enum.uniq() |> Enum.with_index() |> Map.new()

      entries =
        Enum.map(entries, fn {rank, _value, count} -> {Map.fetch!(index, rank), count} end)

      {entries, Enum.map(bound, fn {rank, count} -> {Map.fetch!(index, rank), count} end)}
    end
  end

  # The first block of a partition of the entries, with what is left and the
  # counts of the block, for each way to choose it
  defp first_blocks(entries, bound), do: first_blocks(entries, bound, 1, [], [], [])

  defp first_blocks([{rank, value, count} | entries], bound, min, values, counts, left) do
    bound
    |> choices(rank, count, min)
    |> Enum.flat_map(fn {t, bound} ->
      values = Multiset.dup(value, t, values)
      counts = if t > 0, do: [{rank, t} | counts], else: counts
      left = if t < count, do: [{rank, value, count - t} | left], else: left
      first_blocks(entries, bound, 0, values, counts, left)
    end)
  end

  defp first_blocks([], _bound, _min, values, counts, left),
    do: [{Enum.reverse(values), Enum.reverse(left), Enum.reverse(counts)}]

  # With distinct elements the first block holds the first element and any of
  # the others, those with the first element's block holding most first. The
  # blocks of what is left then follow, and are in the same order whatever the
  # first block. The number of partitions of m elements is the Bell number.
  defp nth_distinct([], _n, _bells), do: []

  defp nth_distinct([first | rest], n, bells) do
    {others, left, n} = choose(rest, length(rest), 0, [], [], n, bells)
    [[first | others] | nth_distinct(left, n, bells)]
  end

  # Decides for each of the other elements, in order, whether it is in the
  # first block, having picked c so far. Including it goes first.
  defp choose([], _total, _c, picked, left, n, _bells),
    do: {Enum.reverse(picked), Enum.reverse(left), n}

  defp choose([element | rest], total, c, picked, left, n, bells) do
    later = length(rest)

    # The partitions with this element in the block, over each number x of the
    # later elements that are in it as well
    with_element =
      Enum.sum(for x <- 0..later, do: Math.binomial(later, x) * elem(bells, total - c - 1 - x))

    if n < with_element,
      do: choose(rest, total, c + 1, [element | picked], left, n, bells),
      else: choose(rest, total, c, picked, [element | left], n - with_element, bells)
  end

  defp last(tuple), do: elem(tuple, tuple_size(tuple) - 1)

  # The Bell numbers from 0 to n, as a tuple, from the Bell triangle. Each row
  # starts with the last number of the row before, and each number is the one
  # before it plus the one above that.
  defp bells(n) do
    {bells, _row} =
      Enum.reduce(1..n//1, {[1], [1]}, fn _, {bells, row} ->
        first = List.last(row)
        {[first | bells], [first | Enum.scan(row, first, &(&1 + &2))]}
      end)

    bells |> Enum.reverse() |> List.to_tuple()
  end

  # How many copies of the entry with rank may go in the block, largest first,
  # and the bound for the entries that follow
  defp choices(:free, _rank, count, min), do: for(t <- count..min//-1, do: {t, :free})

  # The bound holds a value missing from the block, so the block is smaller
  defp choices([{bound_rank, _} | _], rank, count, min) when bound_rank < rank,
    do: choices(:free, rank, count, min)

  defp choices([{rank, bound_count} | bound], rank, count, min) do
    for t <- min(count, bound_count)..min//-1,
        do: {t, if(t == bound_count, do: bound, else: :free)}
  end

  # The bound has none of this value, so neither may the block. Never reached
  # for the first entry, as the bound holds that value or a smaller one.
  defp choices(bound, _rank, _count, 0), do: [{0, bound}]

  defp flat_map(enum, true, fun), do: Stream.flat_map(enum, fun)
  defp flat_map(enum, false, fun), do: Enum.flat_map(enum, fun)

  defp map(enum, true, fun), do: Stream.map(enum, fun)
  defp map(enum, false, fun), do: Enum.map(enum, fun)
end
