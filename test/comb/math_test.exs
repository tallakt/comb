defmodule Comb.MathTest do
  use ExUnit.Case, async: true
  doctest Comb.Math, import: true
  import Comb.Math

  test "first factorial numbers" do
    assert for(n <- 0..4, do: factorial(n)) ==
             [1, 1, 2, 6, 24]
  end

  test "factorial 31" do
    assert factorial(31) == 8_222_838_654_177_922_817_725_562_880_000_000
  end
end
