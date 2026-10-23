# SComb

[![CI](https://github.com/tallakt/scomb/actions/workflows/ci.yml/badge.svg)](https://github.com/tallakt/scomb/actions/workflows/ci.yml)

SComb is Streaming Combinatorics for Elixir. It contains functions such as
`permutations/1` and `combinations/2`. Functions returning large results return
a lazy [`Stream`](https://hexdocs.pm/elixir/Stream.html), so you can take from
results too large to hold in memory, while smaller results may be any
enumerable.

The package contains only Elixir code without any library dependencies.

Where applicable, the library will return sensible results with repeated
parameters: equal elements are interchangeable, so each distinct permutation,
combination, subset or partition is returned once. Repeated elements do not
need to be next to each other. This is best shown in the examples section.

## Installation

Add `scomb` to the dependencies in your `mix.exs`:

```elixir
    def deps do
      [
        {:scomb, "~> 0.2"}
      ]
    end
```

## Examples

### Permutations

```elixir
    iex> permutations(1..3) |> Enum.to_list
    [[1, 2, 3], [2, 1, 3], [1, 3, 2], [3, 1, 2], [2, 3, 1], [3, 2, 1]]

    iex> permutations([1, 1, 2]) |> Enum.to_list
    [[1, 1, 2], [1, 2, 1], [2, 1, 1]]

    iex> permutation_index([1, 3, 2])
    2

    iex> drop_permutations(1..3, 3) |> Enum.to_list
    [[3, 1, 2], [2, 3, 1], [3, 2, 1]]

    iex> nth_permutation(1..3, 3)
    [3, 1, 2]

    iex> count_permutations([1, 1, 2, 2])
    6
```

### Permuted combinations

```elixir
    iex> permuted_combinations(1..3, 2) |> Enum.to_list
    [[1, 2], [2, 1], [1, 3], [3, 1], [2, 3], [3, 2]]
```

### Combinations

```elixir
    iex> combinations(1..3, 2) |> Enum.to_list
    [[1, 2], [1, 3], [2, 3]]

    iex> combinations([1, 1, 2, 2], 3) |> Enum.to_list
    [[1, 1, 2], [1, 2, 2]]

    iex> nth_combination(1..4, 2, 5)
    [3, 4]

    iex> count_combinations(1..3, 2)
    3
```

### Cartesian product

```elixir
    iex> cartesian_product(1..2, 3..4)
    [[1, 3], [1, 4], [2, 3], [2, 4]]

    iex> cartesian_product([1..2, [:a], 3..4]) |> Enum.to_list
    [[1, :a, 3], [1, :a, 4], [2, :a, 3], [2, :a, 4]]
```

### Subsets

```elixir
    iex> subsets(1..3) |> Enum.to_list
    [[], [1], [2], [3], [1, 2], [1, 3], [2, 3], [1, 2, 3]]

    iex> subsets([1, 1, 2]) |> Enum.to_list
    [[], [1], [2], [1, 1], [1, 2], [1, 1, 2]]

    iex> count_subsets(1..3)
    8

    iex> nth_subset(1..3, 4)
    [1, 2]
```

### Selections

```elixir
    iex> selections(1..2, 3) |> Enum.to_list
    [[1, 1, 1], [1, 1, 2], [1, 2, 1], [1, 2, 2], [2, 1, 1], [2, 1, 2],
    [2, 2, 1], [2, 2, 2]]
```

### Partitions

```elixir
    iex> partitions(1..3) |> Enum.to_list
    [[[1, 2, 3]], [[1, 2], [3]], [[1, 3], [2]], [[1], [2, 3]], [[1], [2], [3]]]

    iex> partitions([1, 1, 2]) |> Enum.to_list
    [[[1, 1, 2]], [[1, 1], [2]], [[1, 2], [1]], [[1], [1], [2]]]

    iex> partitions(1..3, min: 2, max: 2) |> Enum.to_list
    [[[1, 2], [3]], [[1, 3], [2]], [[1], [2, 3]]]
```

### Large results

Results are generated lazily, so you can take from results too large to hold
in memory. The `count_*`, `nth_*` and `drop_permutations/2` functions, and
`permutation_index/1`, compute their result directly, without generating the
elements before it.

```elixir
    iex> combinations(1..1000, 500) |> Enum.take(1) |> hd |> Enum.take(3)
    [1, 2, 3]

    iex> count_permutations(1..30)
    265252859812191058636308480000000

    iex> nth_permutation(1..30, 10 ** 30) |> permutation_index
    1000000000000000000000000000000
```

## Development

Each function in `SComb` has a naive counterpart in `bench/naive.ex`, a short
and obviously correct implementation that serves as its specification. The tests
check that both return the same elements, in the same order, for many inputs.
If you find a faster algorithm, and tests are still passing, pull requests will
be considered on Github.

As the package is gradually optimized, we will strive to keep the interface
fixed. Even so, you should not depend on a certain function generating the
exact same sequence between versions of this package. For example, the
`permutation/1` function may return the different permutations in different
orders depending on the algorithm used. This will extend to functions like
`nth_permutation/2` that could return different values between versions.

The interface of the module is more or less compatible with the
[clojure math.combinatorics](https://github.com/clojure/math.combinatorics/)
package, which seemed well thought out.

The package is licenced under Apache 2.0, so if you want to copy code from
other libraries, please make sure that the license of the source will allow
this. Note that the Clojure library mentioned above is licenced more
restrictive than this package. Any source contributed is assumed to be free of
patents and released under the same license as the rest of the code. Please
also refer to the LICENSE file.

## Benchmarking

To measure a revised algorithm, we have supplied a mix task to measure the
speedup compared to a naive (non streamed) version of the algorithm.

```
    $ mix scomb.benchmark
```

Each line gives the time taken as a percentage of the naive version, so
smaller is faster:

```
    [100% - like naive implementation, smaller is faster]

      ...
       2.05%: combinations - 40-2 elements
       5.16%: combinations - 20-10 elements
       4.77%: combinations - 10-5 with repeated elements
      ...
      18.85%: partitions - 9 element range
       2.84%: partitions - 10 element with repetitions
      ...
      15.16%: permutations - 7 element range
       8.22%: permutations - 10 element with repetitions
      ...
```

## Credits

- Martin Svalin / @martinsvalin: Original LazyPermutations module
- Tommy Fisher / @wless1 on Slack: Original combinations and combinations2
- Tallak Tveide / @tallakt: Other stuff

