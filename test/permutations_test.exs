defmodule PermutationsTest do
  use ExUnit.Case, async: true
  doctest Permutations.Naive, import: true
  doctest Permutations.Wless1, import: true
  doctest Permutations.LazyPermutations, import: true
  doctest Permutations.TallakEnum, import: true
  doctest Permutations.TallakStream, import: true
end
