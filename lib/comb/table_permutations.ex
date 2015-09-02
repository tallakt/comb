defmodule Comb.TablePermutations do
  require Comb.Naive

  @table_size 5

  # This is a macro helper
  to_vars = 
    fn enum ->
      for i <- enum, do: "a#{i}" |> String.to_atom |> Macro.var(__MODULE__)
    end

  for count <- 1..@table_size do
    for {perm, i} <- Enum.with_index(Comb.Naive.permutations(1..count)) do
      def do_permutations_table(unquote(count), unquote(i + 1), 
                            [unquote_splicing(to_vars.(count..1))], tail) do
        [unquote_splicing(to_vars.(perm)) | tail]
      end
    end
  end

  def permutations(enum) do
    list = Enum.to_list enum
    count = Enum.count(list)
    do_permutations(list, count, [])
  end

  defp do_permutations([], _, _), do: [[]]

  defp do_permutations(list, count, tail) when count <= @table_size do
    1..Enum.reduce(1..count, &Kernel.*/2)
    |> Stream.map(fn i -> do_permutations_table(count, i, list, tail) end)
  end


  # For permutations larger than table size, approach like naive algorithm
  defp do_permutations(list, count, tail) do
    list
    |> Stream.flat_map(fn el ->
        do_permutations(list -- [el], count - 1, [el|tail])
      end)
  end
end


