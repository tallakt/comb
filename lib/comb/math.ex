defmodule Comb.Math do
  @moduledoc """
  Some useful math functions. These are generally used internally by the
  library.
  """
  factorial_fn = fn n ->
    inner = fn
      0, _ ->
        1

      n, self ->
        n * self.(n - 1, self)
    end

    inner.(n, inner)
  end

  @doc """
  Returns the factorial of a number. Highly optimized for n < 30

  ## Example

      iex> factorial 5
      120

  """
  @spec factorial(non_neg_integer) :: pos_integer
  def factorial(n)

  # generate a table of the first 30 factorials
  for n <- 0..30 do
    def factorial(unquote(n)), do: unquote(factorial_fn.(n))
  end

  def factorial(n) when is_integer(n) and n > 30, do: Enum.reduce(31..n, factorial(30), &*/2)

  @doc """
  Returns the binomial coefficient, the number of ways to choose `k` elements
  from `n`

  ## Example

      iex> binomial 5, 2
      10

      iex> binomial 2, 5
      0

  """
  @spec binomial(non_neg_integer, non_neg_integer) :: non_neg_integer
  def binomial(n, k) when is_integer(n) and is_integer(k) and n >= 0 and k >= 0 do
    if k > n do
      0
    else
      k = min(k, n - k)
      Enum.reduce(1..k//1, 1, fn i, acc -> div(acc * (n - k + i), i) end)
    end
  end

  @doc """
  Returns the multinomial coefficient, the number of ways to arrange groups of
  `counts` interchangeable elements in a row

  ## Example

      iex> multinomial [2, 1]
      3

  """
  @spec multinomial([non_neg_integer]) :: pos_integer
  def multinomial(counts) do
    {result, _} =
      Enum.reduce(counts, {1, 0}, fn count, {acc, sum} ->
        {acc * binomial(sum + count, count), sum + count}
      end)

    result
  end
end
