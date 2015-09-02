# Comb

The `Comb` package contains functions for combinatorics, such as
`permutations/1` and `combinations/2`. Functions returning large lists will
return these as a stream, while smaller values may be any enumerable.

The package contains only Elixir code without any library dependencies.

Where applicable, the library will return sensible results with repeated
parameters. This is best shown in the examples section.

## Examples

### Permutations

```elixir
    iex> permutations(1..3) |> Enum.to_list
    [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1]]

    iex> permutations([1, 1, 2]) |> Enum.to_list
    [[1, 1, 2], [1, 2, 1], [2, 1, 1]]

    iex> permutation_index([1, 3, 2])
    1

    iex> drop_permutations(1..3, 3) |> Enum.to_list
    [[2, 3, 1], [3, 1, 2], [3, 2, 1]]

    iex> nth_permutation(1..3, 3)
    [2, 3, 1]
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
```

### Subsets

```elixir
    iex> subsets(1..3) |> Enum.to_list
    [[], [1], [2], [3], [1, 2], [1, 3], [2, 3], [1, 2, 3]]

    iex> subsets([1, 1, 2]) |> Enum.to_list
    [[], [1], [2], [1, 1], [1, 2], [1, 1, 2]]

    iex> count_subsets(1..3)
    8

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
    [[[1, 1, 2]], [[1, 1], [2]], [[1], [1, 2]], [[1], [1], [2]]]
```

## Development

As of now, some functions are optimized while others are not.  We are inviting
anyone with spare time and an interest to try to optimize any of these
functions. If there is some performance gain, and tests are still passing, pull
requests will be considered on Github.

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

```elixir
    $ mix benchmark
```

```
Testing permutation
-- naive
*** #Function<1.110413037/0 in Mix.Tasks.Benchmark.run/1> ***
1.5 sec     15 iterations   102477.34 μs/op

-- SJT
*** #Function<2.110413037/0 in Mix.Tasks.Benchmark.run/1> ***
2.1 sec      7 iterations   312474.58 μs/op

-- LazyPermutations
*** #Function<3.110413037/0 in Mix.Tasks.Benchmark.run/1> ***
2.2 sec      7 iterations   318748.15 μs/op

-- Table
*** #Function<4.110413037/0 in Mix.Tasks.Benchmark.run/1> ***
1.7 sec     31 iterations   55273.88 μs/op

-- Table stream
*** #Function<5.110413037/0 in Mix.Tasks.Benchmark.run/1> ***
1.3 sec     31 iterations   42615.81 μs/op

Testing combination
-- Wless1 Optimized
*** #Function<6.110413037/0 in Mix.Tasks.Benchmark.run/1> ***
1.4 sec    32K iterations   43.37 μs/op

-- Wless1 Naive
*** #Function<7.110413037/0 in Mix.Tasks.Benchmark.run/1> ***
1.4 sec    16K iterations   88.61 μs/op
```

## Credits

- Martin Svalin / @martinsvalin: Original LazyPermutations module
- Tommy Fisher / @wless1 on Slack: Original combinations and combinations2
- Tallak Tveide / @tallakt: Other stuff

