defmodule SComb.Sequence do
  @moduledoc """
  The lazy sequence of results returned by `SComb.permutations/1`,
  `SComb.combinations/2`, `SComb.subsets/1`, `SComb.selections/2`,
  `SComb.partitions/1` and `SComb.combinations_with_replacement/2`.

  A sequence is an `Enumerable` that generates its elements one at a time, like
  a `Stream`. In addition it knows its size and how to find an element by its
  index, so functions such as `Enum.count/1`, `Enum.at/2`, `Enum.slice/2`,
  `Enum.take/2` with a negative amount and `Enum.random/1` do not generate the
  elements before the ones asked for:

      iex> sequence = SComb.permutations(1..30)
      iex> Enum.count(sequence)
      265252859812191058636308480000000
      iex> Enum.at(sequence, 10 ** 30) |> Enum.take(3)
      [14, 28, 9]

  Indexing is only used for inputs of moderate size, as the size of the
  sequence has to be cheap to find. For larger inputs the sequence is
  streamed, and `Enum.count/1` still returns the size.
  """

  defstruct [:name, :stream, :count, :nth, :from, indexable: true]

  @typedoc "A lazy, indexable sequence of results"
  @type t :: %__MODULE__{
          name: String.t(),
          stream: Enumerable.t(),
          count: (-> non_neg_integer),
          nth: (non_neg_integer -> term),
          from: (non_neg_integer -> Enumerable.t()),
          indexable: boolean
        }

  # The sequence has the elements of stream, count elements, and nth finds the
  # element at an index. from gives the elements from an index on, which may be
  # faster than finding each.
  @doc false
  @spec new(String.t(), Enumerable.t(), (-> non_neg_integer), (non_neg_integer -> term), keyword) ::
          t
  def new(name, stream, count, nth, opts \\ []) do
    %__MODULE__{
      name: name,
      stream: stream,
      count: count,
      nth: nth,
      from: Keyword.get(opts, :from, &from(nth, &1)),
      indexable: Keyword.get(opts, :indexable, true)
    }
  end

  defp from(nth, start), do: Stream.map(Stream.iterate(start, &(&1 + 1)), nth)

  # The `amount` elements from index `start`, every `step`
  @doc false
  @spec slice(t, non_neg_integer, pos_integer, pos_integer) :: list
  def slice(%__MODULE__{nth: nth}, start, 1, _step), do: [nth.(start)]

  def slice(%__MODULE__{stream: stream}, 0, amount, step),
    do: stream |> Stream.take_every(step) |> Enum.take(amount)

  def slice(%__MODULE__{from: from}, start, amount, step),
    do: start |> from.() |> Stream.take_every(step) |> Enum.take(amount)

  defimpl Enumerable do
    def reduce(%{stream: stream}, acc, fun), do: Enumerable.reduce(stream, acc, fun)

    def count(%{count: count}), do: {:ok, count.()}

    def member?(_sequence, _element), do: {:error, __MODULE__}

    def slice(%{indexable: true, count: count} = sequence),
      do: {:ok, count.(), &SComb.Sequence.slice(sequence, &1, &2, &3)}

    def slice(_sequence), do: {:error, __MODULE__}
  end

  defimpl Inspect do
    def inspect(%{name: name}, _opts), do: "#SComb.Sequence<#{name}>"
  end
end
