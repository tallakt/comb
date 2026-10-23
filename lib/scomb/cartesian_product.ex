defmodule SComb.CartesianProduct do
  @moduledoc false

  alias SComb.Multiset

  # Products with at most this many elements are built as lists, as streams
  # cost more per element
  @eager_limit 2000

  def product(enums) do
    lists = Enum.map(enums, &Enum.to_list/1)
    # The size of the product of each list and those following it
    sizes =
      List.foldr(lists, [1], fn list, [size | _] = sizes -> [length(list) * size | sizes] end)

    generate(lists, sizes)
  end

  def count(enums), do: enums |> Enum.map(&Enum.count/1) |> Enum.reduce(1, &*/2)

  # The index written with a digit for each list, the last list the least
  # significant, so each digit is the position in its list
  def nth(enums, n) do
    lists = Enum.map(enums, &List.to_tuple(Enum.to_list(&1)))
    sizes = Enum.map(lists, &tuple_size/1)
    i = Multiset.index!(n, Enum.reduce(sizes, 1, &*/2))

    {picked, 0} =
      lists
      |> Enum.reverse()
      |> Enum.map_reduce(i, fn list, i ->
        {elem(list, rem(i, tuple_size(list))), div(i, tuple_size(list))}
      end)

    Enum.reverse(picked)
  end

  def selections(enum, k), do: product(List.duplicate(Enum.uniq(enum), k))

  def count_selections(enum, k), do: length(Enum.uniq(enum)) ** k

  # The index written in base d, one digit for each of the k positions
  def nth_selection(enum, k, n) do
    values = enum |> Enum.uniq() |> List.to_tuple()
    d = tuple_size(values)

    n
    |> Multiset.index!(d ** k)
    |> digits(d, k, [])
    |> Enum.map(&elem(values, &1))
  end

  defp digits(_i, _d, 0, acc), do: acc
  defp digits(i, d, k, acc), do: digits(div(i, d), d, k - 1, [rem(i, d) | acc])

  defp generate([], _sizes), do: [[]]

  defp generate([list | lists], [size | sizes]) do
    # The tails are generated once, and shared by all the elements of list
    tails = generate(lists, sizes)

    cond do
      size <= @eager_limit -> for x <- list, tail <- tails, do: [x | tail]
      is_list(tails) -> Stream.flat_map(list, fn x -> for tail <- tails, do: [x | tail] end)
      true -> Stream.flat_map(list, fn x -> Stream.map(tails, &[x | &1]) end)
    end
  end
end
