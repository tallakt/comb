defmodule Mix.Tasks.Comb.Benchmark do
  use Mix.Task

  def compare(description, function, args, n \\ 5) do
    # these functions return either an enum or integer

    [t0, t] = for module <- [Comb.Naive, Comb] do
      {time, _} = :timer.tc fn ->
        for _ <- 1..n do
          case apply(module, function, args) do
            n when is_integer(n) ->
              nil
            enum ->
              Stream.run(enum)
          end
        end
      end
      time
    end
    percentage = Float.to_string(100 * t / t0, decimals: 1) |> String.rjust(6)
    IO.puts "#{percentage}%: #{function} - #{description}"
  end
  @repeated6 [1, 1, 1, 2, 2, 3]
  @repeated10 [1, 1, 1, 2, 2, 3, 5, 6, 7, 8]

  @shortdoc "Compare speedup of Comb functions relative to naive impl"
  def run(_) do
    IO.puts ""
    IO.puts "[100% - like naive implementation, smaller is faster]"
    IO.puts ""
    [
      {"2+2 element ranges",
        :cartesian_product, [1..2, 1..2]},
      {"5+5 element ranges",
        :cartesian_product, [1..5, 1..5]},
      :space,
      {"4-2 elements",
        :combinations, [1..6, 2]},
      {"6-2 elements",
        :combinations, [1..6, 2]},
      {"40-2 elements",
        :combinations, [1..40, 2]},
      {"6-2 with repeated elements",
        :combinations, [[1, 1, 1, 2, 2, 3], 2]},
      :space,
      {"6-2 elements",
        :count_combinations, [1..6, 2]},
      {"6-2 with repeated elements",
        :count_combinations, [@repeated6, 2]},
      :space,
      {"6-2, n=10",
        :nth_combination, [1..6, 2, 10]},
      {"10-2 with repeated elements, n=10",
        :nth_combination, [@repeated10, 2, 10]},
      :space,
      {"4 element range",
        :partitions, [1..4]},
      {"6 element with repetitions",
        :partitions, [@repeated6]},
      :space,
      {"7 element range",
        :permutations, [1..7]},
      {"6 element with repetitions",
        :permutations, [@repeated6]},
      :space,
      {"6 element range",
        :count_permutations, [1..6]},
      {"6 element with repetitions",
        :count_permutations, [@repeated6]},
      :space,
      {"6 element range, drop 100",
        :drop_permutations, [1..6, 100]},
      {"6 element range with repetitions, drop 100",
        :drop_permutations, [@repeated6, 100]},
      :space,
      {"6 element range, n=100",
        :nth_permutation, [1..6, 100]},
      {"6 element range with repetitions, n=20",
        :nth_permutation, [@repeated6, 20]},
      :space,
      {"6 element range",
        :permutation_index, [[1, 2, 3, 6, 4, 5]]},
      {"6 element range with repetition",
        :permutation_index, [[1, 2, 1, 6, 1, 5]]},
      :space,
      {"6-3 element range",
        :selections, [1..6, 3]},
      :space,
      {"6 element range",
        :subsets, [1..6]},
      :space,
      {"6 element range",
        :count_subsets, [1..6]},
      :end
    ]
    |> Enum.each(fn
        {d, f, a} ->
          compare d, f, a
        a when a in [:space, :end] ->
          IO.puts ""
      end)
  end
end

