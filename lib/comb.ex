defmodule Comb do


  defmodule Table do
    require Comb.Naive

    @table_size 5

    # This is a macro helper
    to_vars = 
      fn enum ->
        for i <- enum, do: "a#{i}" |> String.to_atom |> Macro.var(__MODULE__)
      end

    for count <- 1..@table_size do
      for {perm, i} <- Enum.with_index(Comb.Naive.permutations(1..count)) do
        def do_permutation_table(unquote(count), unquote(i + 1), 
                              [unquote_splicing(to_vars.(count..1))], tail) do
          [unquote_splicing(to_vars.(perm)) | tail]
        end
      end
    end

    def permutation(enum) do
      list = Enum.to_list enum
      count = Enum.count(list)
      do_permutation(list, count, [])
    end

    defp do_permutation([], _, _), do: [[]]

    defp do_permutation(list, count, tail) when count <= @table_size do
      1..Enum.reduce(1..count, &Kernel.*/2)
      |> Stream.map(fn i -> do_permutation_table(count, i, list, tail) end)
    end


    # For permutations larger than table size, approach like naive algorithm
    defp do_permutation(list, count, tail) do
      list
      |> Stream.flat_map(fn el ->
          do_permutation(list -- [el], count - 1, [el|tail])
        end)
    end
  end


  defdelegate permutations(enum), to: Comb.Naive

  defmodule Wless1 do
    @doc """
    ## Examples

        iex> combinations([1, 2, 3], 2)
        [[1, 2], [1, 3], [2, 3]]

    """
    def combinations(enum, k) do
      List.last(do_combinations(enum, k))
    end

    defp do_combinations(enum, k) do
      combinations_by_length = [[[]]|List.duplicate([], k)]

      list = Enum.to_list(enum)
      List.foldr list, combinations_by_length, fn x, next ->
        sub = :lists.droplast(next)
        step = [[]|(for l <- sub, do: (for s <- l, do: [x|s]))]
        :lists.zipwith(&:lists.append/2, step, next)
      end
    end
  end

  defdelegate combinations(enum, n), to: Comb.Wless1

end
