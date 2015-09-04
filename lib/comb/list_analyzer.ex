defmodule Comb.ListAnalyzer do
  defstruct freq: %{}, count: 0, max_freq: 0
  alias Comb.ListAnalyzer

  @type t :: %__MODULE__{}

  @spec analyze(Enum.t) :: {Map.t, integer, integer}
  def analyze(enum) do
    enum
    |> Enum.reduce(%ListAnalyzer{}, fn e, %ListAnalyzer{freq: f, count: c, max_freq: m}  ->
        new_freq = Map.update(f, e, 1, &(&1 + 1))
        new_max = max(Map.fetch!(new_freq, e), m)
        %ListAnalyzer{freq: new_freq, max_freq: new_max, count: c + 1}
      end)
  end

  @spec any_duplicates?(t) :: boolean
  def any_duplicates?(%ListAnalyzer{max_freq: m}), do: m > 1

  @spec all_unique?(t) :: boolean
  def all_unique?(%ListAnalyzer{max_freq: m}), do: m <= 1
end
