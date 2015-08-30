Comb
====

This repo is just for testing various versions of permutations and combinations
of an Enumerable in Elixir

## Current benchmark

```
Testing permutation
-- naive
*** #Function<1.128418364/0 in Mix.Tasks.Benchmark.run/1> ***
1.6 sec     15 iterations   108859.2 μs/op

-- SJT
*** #Function<2.128418364/0 in Mix.Tasks.Benchmark.run/1> ***
1.0 sec      3 iterations   342124.0 μs/op

-- LazyPermutations
*** #Function<3.128418364/0 in Mix.Tasks.Benchmark.run/1> ***
1.0 sec      3 iterations   357009.0 μs/op

Testing combination
-- Wless1 Optimized
*** #Function<4.128418364/0 in Mix.Tasks.Benchmark.run/1> ***
1.5 sec    32K iterations   48.76 μs/op

-- Wless1 Naive
*** #Function<5.128418364/0 in Mix.Tasks.Benchmark.run/1> ***
1.5 sec    16K iterations   94.09 μs/op
```

