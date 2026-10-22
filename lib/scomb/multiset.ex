defmodule SComb.Multiset do
  @moduledoc false

  # A multiset is held as a list of `{value, count}` with the distinct values
  # in order of first appearance. Repeated elements are interchangeable, so
  # the functions in `SComb` work on these rather than on the input list.

  @type t :: [{term, pos_integer}]

  @spec from_enum(Enum.t()) :: t
  def from_enum(enum) do
    {values, counts} =
      Enum.reduce(enum, {[], %{}}, fn x, {values, counts} ->
        case counts do
          %{^x => count} -> {values, %{counts | x => count + 1}}
          %{} -> {[x | values], Map.put(counts, x, 1)}
        end
      end)

    values
    |> Enum.reverse()
    |> Enum.map(&{&1, Map.fetch!(counts, &1)})
  end

  @spec counts(t) :: [pos_integer]
  def counts(multiset), do: Enum.map(multiset, &elem(&1, 1))

  @spec size(t) :: non_neg_integer
  def size(multiset), do: multiset |> counts() |> Enum.sum()

  @spec distinct?(t) :: boolean
  def distinct?(multiset), do: Enum.all?(multiset, &match?({_, 1}, &1))

  # Prepends `count` copies of `value` to `list`
  @spec dup(term, non_neg_integer, list) :: list
  def dup(_value, 0, list), do: list
  def dup(value, count, list), do: dup(value, count - 1, [value | list])
end
