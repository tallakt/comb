defmodule Mix.Tasks.Benchmark do
  use Mix.Task

  def run(_) do
    numbers = for x <- 1..8, do: x

    IO.puts "Testing permutation"
    IO.puts "-- naive"
    Benchwarmer.benchmark(
      fn -> Permutations.Naive.permutation(numbers) end
    )

    IO.puts "-- SJT"
    Benchwarmer.benchmark(
      fn -> Permutations.SJT.permutation(numbers) |> Enum.to_list end
    )

    IO.puts "-- LazyPermutations"
    Benchwarmer.benchmark(
      fn -> Permutations.LazyPermutations.permutation(numbers) |> Enum.to_list end
    )

    IO.puts "Testing combination"
    IO.puts "-- Wless1 Optimized"
    Benchwarmer.benchmark(
      fn -> Permutations.Wless1.combinations(numbers, 5) end
    )

    IO.puts "-- Wless1 Naive"
    Benchwarmer.benchmark(
      fn -> Permutations.Wless1.combinations2(numbers, 5) end
    )
  end
end

