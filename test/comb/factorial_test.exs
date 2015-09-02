defmodule Comb.FactorialTest do
  use ExUnit.Case, async: true
  import Comb.Factorial
  doctest Comb.Factorial, import: true

  test "first factorial numbers" do
    assert (for n <- 0..4, do: factorial(n)) ==
      [1, 1, 2, 6, 24]
  end

  test "factorial 31" do
    8222838654177922817725562880000000
  end
end



