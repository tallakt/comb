defmodule SComb.SequenceTest do
  use ExUnit.Case, async: true
  import SComb
  doctest SComb.Sequence

  defp sequences do
    [
      permutations([1, 1, 2, 3, 3]),
      combinations(1..7, 3),
      subsets([1, 1, 2, 3]),
      selections(1..3, 3),
      partitions([1, 2, 3, 4, 1]),
      partitions(1..5),
      combinations_with_replacement(1..4, 3),
      # Nothing to return, and the one empty result
      combinations(1..3, 5),
      permutations([])
    ]
  end

  test "Enum functions give the same results as for the list of elements" do
    for sequence <- sequences() do
      list = Enum.to_list(sequence)
      n = length(list)

      assert Enum.count(sequence) == n
      assert Enum.empty?(sequence) == (n == 0)
      assert Enum.reverse(sequence) == Enum.reverse(list)
      assert Enum.split(sequence, 3) == Enum.split(list, 3)
      assert Enum.take_every(sequence, 3) == Enum.take_every(list, 3)
      assert Enum.drop(sequence, 2) == Enum.drop(list, 2)
      assert Enum.drop(sequence, -2) == Enum.drop(list, -2)

      for element <- list, do: assert(Enum.member?(sequence, element))
      refute Enum.member?(sequence, :not_there)

      for i <- (-n - 2)..(n + 2) do
        assert Enum.at(sequence, i, :none) == Enum.at(list, i, :none), inspect({list, i})
        assert Enum.fetch(sequence, i) == Enum.fetch(list, i)

        for amount <- 0..4 do
          assert Enum.slice(sequence, i, amount) == Enum.slice(list, i, amount)
          assert Enum.take(sequence, i) == Enum.take(list, i)
        end
      end

      for first <- Enum.take_every(-n..n, 4), last <- Enum.take_every(-n..n, 5), step <- 1..3 do
        range = first..last//step
        assert Enum.slice(sequence, range) == Enum.slice(list, range), inspect({list, range})
      end

      if n > 0, do: assert(Enum.random(sequence) in list)
    end
  end

  test "indexing reaches far into huge sequences without generating the elements" do
    permutations = permutations(1..30)
    assert Enum.count(permutations) == count_permutations(1..30)
    assert Enum.at(permutations, 10 ** 30) == nth_permutation(1..30, 10 ** 30)
    assert Enum.at(permutations, -1) == Enum.to_list(30..1//-1)

    assert Enum.slice(permutations, 10 ** 30, 2) ==
             [nth_permutation(1..30, 10 ** 30), nth_permutation(1..30, 10 ** 30 + 1)]

    assert Enum.take(permutations, -1) == [Enum.to_list(30..1//-1)]
    assert Enum.random(permutations) |> permutation_index() < count_permutations(1..30)

    combinations = combinations(1..100, 50)
    assert Enum.at(combinations, 10 ** 28) == nth_combination(1..100, 50, 10 ** 28)

    assert Enum.slice(combinations, 10 ** 28, 3) ==
             Enum.map(0..2, &nth_combination(1..100, 50, 10 ** 28 + &1))

    partitions = partitions(1..30)
    assert Enum.at(partitions, 10 ** 20) == nth_partition(1..30, 10 ** 20)
    assert Enum.count(partitions) == count_partitions(1..30)

    assert Enum.at(subsets(1..100), 10 ** 29) == nth_subset(1..100, 10 ** 29)
    assert Enum.at(selections(1..10, 100), 10 ** 99) == nth_selection(1..10, 100, 10 ** 99)
  end

  test "inputs too large to index are still streamed" do
    assert permutations(1..5000) |> Enum.take(2) ==
             [Enum.to_list(1..5000), [2, 1 | Enum.to_list(3..5000)]]

    assert combinations(1..5000, 2) |> Enum.at(1) == [1, 3]

    assert partitions(1..300) |> Enum.take(2) == [
             [Enum.to_list(1..300)],
             [Enum.to_list(1..299), [300]]
           ]

    assert Enum.count(subsets(1..3000)) == 2 ** 3000
  end

  test "the input is read once" do
    {:ok, agent} = Agent.start_link(fn -> 0 end)

    input =
      Stream.map(1..4, fn x ->
        Agent.update(agent, &(&1 + 1))
        x
      end)

    sequence = permutations(input)
    reads = Agent.get(agent, & &1)
    assert Enum.count(sequence) == 24
    assert Enum.at(sequence, 5) == nth_permutation(1..4, 5)
    assert Enum.to_list(sequence) |> length() == 24
    assert Agent.get(agent, & &1) == reads
  end

  test "inspect does not print the functions" do
    assert inspect(permutations(1..3)) == "#SComb.Sequence<permutations>"
    assert inspect(combinations(1..3, 2)) == "#SComb.Sequence<combinations>"
  end

  test "partitions with limits are a stream of the matching partitions" do
    assert Enum.to_list(partitions(1..3, min: 2)) ==
             Enum.filter(partitions(1..3), &(length(&1) >= 2))
  end
end
