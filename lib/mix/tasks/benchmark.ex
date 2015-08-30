defmodule Mix.Tasks.Benchmark do
  use Mix.Task

  def run_tallak_stream(enumerable) do
    Permutations.TallakStream.permutation(enumerable) 
    |> Enum.to_list
  end

  def run_tallak_maps_stream(enumerable) do
    Permutations.TallakMaps.permutation(enumerable) 
    |> Enum.to_list
  end

  def run_lazy_stream(enumerable) do
    Permutations.LazyPermutations.permutation(enumerable) 
    |> Enum.to_list
  end

  def run(_) do
    numbers = for x <- 1..8, do: x

    IO.puts "Testing permutation"
    Benchwarmer.benchmark(
      [ 
        &Permutations.Naive.permutation/1,
        &Permutations.TallakEnum.permutation/1,
        &run_tallak_stream/1,
        &run_tallak_maps_stream/1,
        &run_lazy_stream/1,
      ],
      [numbers]
    )

    IO.puts "Testing combination"
    Benchwarmer.benchmark(
      [ 
        &Permutations.Wless1.combinations/2,
        &Permutations.Wless1.combinations2/2
      ],
      [numbers, 5]
    )
  end
end

