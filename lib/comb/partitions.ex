defmodule Comb.Partitions do
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

  alias Comb.Multiset

  # Partitions of at most this many elements are built as lists, as streams
  # cost more per element
  @eager_size 8

  def partitions(enum) do
    multiset = Multiset.from_enum(enum)

    multiset
    |> Enum.with_index(fn {value, count}, rank -> {rank, value, count} end)
    |> generate(:free, Multiset.size(multiset))
  end

  # The partitions of the entries with no block greater than bound
  defp generate([], _bound, _size), do: [[]]
  defp generate(entries, bound, size), do: fill(entries, bound, 1, [], [], [], size)

  # Decides how many copies of each entry go in the next block, largest first,
  # then partitions what is left. The block and what is left are built
  # reversed. bound holds the counts of the previous block not yet passed, or
  # is :free once the block is smaller.
  defp fill([{rank, value, count} | entries], bound, min, values, counts, left, size) do
    bound
    |> choices(rank, count, min)
    |> flat_map(size > @eager_size, fn {t, bound} ->
      values = Multiset.dup(value, t, values)
      counts = if t > 0, do: [{rank, t} | counts], else: counts
      left = if t < count, do: [{rank, value, count - t} | left], else: left
      fill(entries, bound, 0, values, counts, left, size - t)
    end)
  end

  defp fill([], _bound, _min, values, counts, left, size) do
    block = Enum.reverse(values)

    left
    |> Enum.reverse()
    |> generate(Enum.reverse(counts), size)
    |> map(size > @eager_size, &[block | &1])
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
