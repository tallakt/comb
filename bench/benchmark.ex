defmodule Mix.Tasks.Scomb.Benchmark do
  use Mix.Task

  def compare(description, function, args) do
    [t0, t] =
      for module <- [SComb.Naive, SComb] do
        # these functions return either an enum or integer
        run = fn ->
          case apply(module, function, args) do
            n when is_integer(n) -> nil
            enum -> Stream.run(enum)
          end
        end

        # warm up, which also loads the modules
        run.()
        time_per_run(run, 1)
      end

    percentage = :erlang.float_to_binary(100 * t / t0, decimals: 2) |> String.pad_leading(7)
    IO.puts("#{percentage}%: #{function} - #{description}")
  end

  # Doubles the number of runs until they take long enough to time reliably
  defp time_per_run(run, n) do
    {time, _} = :timer.tc(fn -> for _ <- 1..n, do: run.() end)
    if time < 50_000, do: time_per_run(run, 2 * n), else: time / n
  end

  @repeated6 [1, 1, 1, 2, 2, 3]
  @repeated10 [1, 1, 1, 2, 2, 3, 5, 6, 7, 8]

  @shortdoc "Compare speedup of SComb functions relative to naive impl"
  def run(_) do
    IO.puts("")
    IO.puts("[100% - like naive implementation, smaller is faster]")
    IO.puts("")

    [
      {"2+2 element ranges", :cartesian_product, [1..2, 1..2]},
      {"5+5 element ranges", :cartesian_product, [1..5, 1..5]},
      {"4x10 element ranges", :cartesian_product, [List.duplicate(1..10, 4)]},
      {"4x10 element ranges", :count_cartesian_product, [List.duplicate(1..10, 4)]},
      {"4x10 element ranges, n=5000", :nth_cartesian_product, [List.duplicate(1..10, 4), 5000]},
      :space,
      {"4-2 elements", :combinations, [1..4, 2]},
      {"6-2 elements", :combinations, [1..6, 2]},
      {"40-2 elements", :combinations, [1..40, 2]},
      {"20-10 elements", :combinations, [1..20, 10]},
      {"6-2 with repeated elements", :combinations, [@repeated6, 2]},
      {"10-5 with repeated elements", :combinations, [@repeated10, 5]},
      :space,
      {"6-2 elements", :count_combinations, [1..6, 2]},
      {"6-2 with repeated elements", :count_combinations, [@repeated6, 2]},
      :space,
      {"6-2, n=10", :nth_combination, [1..6, 2, 10]},
      {"10-2 with repeated elements, n=10", :nth_combination, [@repeated10, 2, 10]},
      :space,
      {"6-3 elements", :permuted_combinations, [1..6, 3]},
      {"6-3 with repeated elements", :permuted_combinations, [@repeated6, 3]},
      {"6-3 elements", :count_permuted_combinations, [1..6, 3]},
      {"6-3 with repeated elements", :count_permuted_combinations, [@repeated6, 3]},
      {"6-3, n=50", :nth_permuted_combination, [1..6, 3, 50]},
      {"6-3 with repeated elements, n=10", :nth_permuted_combination, [@repeated6, 3, 10]},
      :space,
      {"6-3 elements", :combinations_with_replacement, [1..6, 3]},
      {"6-3 elements", :count_combinations_with_replacement, [1..6, 3]},
      {"6-3, n=20", :nth_combination_with_replacement, [1..6, 3, 20]},
      :space,
      {"4 element range", :partitions, [1..4]},
      {"9 element range", :partitions, [1..9]},
      {"6 element with repetitions", :partitions, [@repeated6]},
      {"10 element with repetitions", :partitions, [@repeated10]},
      :space,
      {"7 element range", :permutations, [1..7]},
      {"6 element with repetitions", :permutations, [@repeated6]},
      {"10 element with repetitions", :permutations, [@repeated10]},
      :space,
      {"6 element range", :count_permutations, [1..6]},
      {"6 element with repetitions", :count_permutations, [@repeated6]},
      :space,
      {"6 element range, drop 100", :drop_permutations, [1..6, 100]},
      {"6 element range with repetitions, drop 20", :drop_permutations, [@repeated6, 20]},
      :space,
      {"6 element range, n=100", :nth_permutation, [1..6, 100]},
      {"6 element range with repetitions, n=20", :nth_permutation, [@repeated6, 20]},
      :space,
      {"6 element range", :permutation_index, [[1, 2, 3, 6, 4, 5]]},
      {"6 element range with repetition", :permutation_index, [[1, 2, 1, 6, 1, 5]]},
      :space,
      {"6-3 element range", :selections, [1..6, 3]},
      {"8-5 element range", :selections, [1..8, 5]},
      :space,
      {"6 element range", :count_partitions, [1..6]},
      {"6 element with repetitions", :count_partitions, [@repeated6]},
      :space,
      {"6 element range, n=100", :nth_partition, [1..6, 100]},
      {"6 element with repetitions, n=5", :nth_partition, [@repeated6, 5]},
      :space,
      {"6-3 element range", :count_selections, [1..6, 3]},
      {"6-3 element range, n=100", :nth_selection, [1..6, 3, 100]},
      :space,
      {"6 element range", :subsets, [1..6]},
      {"14 element range", :subsets, [1..14]},
      :space,
      {"6 element range", :count_subsets, [1..6]},
      :space,
      {"10 element range, n=500", :nth_subset, [1..10, 500]},
      :end
    ]
    |> Enum.each(fn
      {d, f, a} ->
        compare(d, f, a)

      a when a in [:space, :end] ->
        IO.puts("")
    end)
  end
end
