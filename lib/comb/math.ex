defmodule Comb.Math do
  @moduledocs """
  Some useful math functions. These are generally used internally by the
  library.
  """
  factorial_fn = fn n ->
    inner = fn
      0, _ ->
        1
      n, self ->
        n * self.(n-1, self)
    end
    inner.(n,inner)
  end

  @doc """
  Returns the factorial of a number. Highly optimized for n < 30

  ## Example

      iex> factorial 5
      120

  """
  @spec factorial(integer) :: integer
  def factorial(n)

  # generate a table of the first 30 factorials
  for n <- 0..30 do
    def factorial(unquote(n)), do: unquote(factorial_fn.(n))
  end

  def factorial(n), do: n * factorial(n - 1)
end
