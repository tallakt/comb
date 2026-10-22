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

  test "binomial matches factorials" do
    for n <- 0..40, k <- 0..n do
      assert binomial(n, k) == div(factorial(n), factorial(k) * factorial(n - k))
    end
  end

  test "multinomial matches factorials" do
    for counts <- [[], [0], [3], [1, 1, 1], [2, 3, 1], [5, 0, 7]] do
      expected = Enum.reduce(counts, factorial(Enum.sum(counts)), &div(&2, factorial(&1)))
      assert multinomial(counts) == expected
    end
  end
end
