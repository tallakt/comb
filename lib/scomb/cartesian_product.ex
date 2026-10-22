defmodule SComb.CartesianProduct do
  @moduledoc false

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

  def selections(enum, k), do: product(List.duplicate(Enum.uniq(enum), k))

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
