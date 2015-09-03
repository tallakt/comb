defmodule Comb.NaiveTest do
  use ExUnit.Case, async: true
  import Comb.Naive

  test "cartesian product" do
    assert cartesian_product(1..2, 3..4) == [[1, 3], [1, 4], [2, 3], [2, 4]]
  end
  
  test "combinations basic usage" do
    assert combinations(1..3, 2) == [[1, 2], [1, 3], [2, 3]]
  end

  test "combinations repeated parameters" do
    assert combinations([1, 1, 1, 2, 2], 3) == [[1, 1, 1], [1, 1, 2], [1, 2, 2]]
  end

  test "count_combinations basic usage" do
    assert count_combinations(1..3, 2) == 3
  end

  test "count_combinations repeated parameters" do
    assert count_combinations([1, 1, 1, 2, 2], 2) == 3
  end

  test "count_subsets basic usage" do
    assert count_subsets(1..3) == 8
  end

  test "count_subsets repeated parameters" do
    assert count_subsets([1, 1, 2]) == 6
  end

  test "drop permutations basic usage" do
    assert drop_permutations(1..3, 3) == (permutations(1..3) |> Enum.drop(3))
  end

  test "drop permutations repeated parameters" do
    assert drop_permutations([1, 1, 2, 2], 3) ==
      (permutations([1, 1, 2, 2]) |> Enum.drop(3))
  end


  test "nth_combination basic usage" do
    assert nth_combination(1..4, 2, 5) ==
      (combinations(1..4, 2) |> Enum.fetch!(5))
  end

  test "nth_combination repeated parameters" do
    assert nth_combination([1, 1, 2, 2, 3], 2, 4) ==
      (combinations([1, 1, 2, 2, 3], 2) |> Enum.fetch!(4))
  end

  test "nth_permutation basic usage" do
    assert nth_permutation(1..3, 3) == (permutations(1..3) |> Enum.fetch!(3))
  end

  test "nth_permutation repeated parameters" do
    assert nth_permutation([1, 1, 2, 2], 3) ==
      (permutations([1, 1, 2, 2]) |> Enum.fetch!(3))
  end

  test "partitions basic usage" do
    assert partitions(1..3) ==
      [[[1, 2, 3]], [[1, 2], [3]], [[1, 3], [2]], [[1], [2, 3]], [[1], [2], [3]]]
  end

  test "partitions repeated parameters" do
    assert partitions([1, 1, 2]) ==
      [[[1, 1, 2]], [[1, 1], [2]], [[1], [1, 2]], [[1], [1], [2]]]
  end

  test "permutation_index basic usage" do
    assert permutation_index(nth_permutation(1..3, 3)) == 3
    assert permutation_index(nth_permutation(1..3, 5)) == 5
  end

  test "permutation_index repeated parameters" do
    # Note naive doesnt support unsorted elements
    perm = permutations([1, 1, 1, 2, 2, 3]) |> Enum.fetch!(3)
    assert permutation_index(perm) == 3
  end

  test "permutations basic usage" do
    assert permutations(1..3)|> Enum.sort ==
      Enum.sort([[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]])
  end

  test "permutations repeated parameters" do
    assert permutations([1, 1, 2]) |> Enum.sort ==
      [[1, 1, 2], [1, 2, 1], [2, 1, 1]] |> Enum.sort
  end

  test "subsets basic usage" do
    assert subsets(1..3) ==
      [[], [1], [2], [3], [1, 2], [1, 3], [2, 3], [1, 2, 3]]
  end

  test "subsets repeated parameters" do
    assert subsets([1, 1, 2]) == [[], [1], [2], [1, 1], [1, 2], [1, 1, 2]]
  end

  test "selections basic usage" do
    assert selections(1..2, 3) == 
    [[1, 1, 1], [1, 1, 2], [1, 2, 1], [1, 2, 2], [2, 1, 1], [2, 1, 2],
      [2, 2, 1], [2, 2, 2]]
  end
end

