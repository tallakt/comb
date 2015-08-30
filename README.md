Permutations
============

This repo is just for testing various versions of permutations and combinations
of an Enumerable in Elixir

## Current benchmark

```
Testing permutation
-- naive
*** #Function<1.30592332/0 in Mix.Tasks.Benchmark.run/1> ***
1.6 sec     15 iterations   108697.07 μs/op

-- tallaks enum impl
*** #Function<2.30592332/0 in Mix.Tasks.Benchmark.run/1> ***
1.8 sec      7 iterations   257843.86 μs/op

-- tallaks stream impl
*** #Function<3.30592332/0 in Mix.Tasks.Benchmark.run/1> ***
1.7 sec      1 iterations   1756526.0 μs/op

-- tallaks maps impl
*** #Function<4.30592332/0 in Mix.Tasks.Benchmark.run/1> ***
1.1 sec      1 iterations   1152160.0 μs/op

-- SJT
*** #Function<5.30592332/0 in Mix.Tasks.Benchmark.run/1> ***
1.8 sec     2K iterations   893.82 μs/op

-- LazyPermutations
*** #Function<6.30592332/0 in Mix.Tasks.Benchmark.run/1> ***
1.6 sec      7 iterations   231753.86 μs/op

Testing combination
-- Wless1 Optimized
*** #Function<7.30592332/0 in Mix.Tasks.Benchmark.run/1> ***
1.4 sec    32K iterations   43.69 μs/op

-- Wless1 Naive
*** #Function<8.30592332/0 in Mix.Tasks.Benchmark.run/1> ***
1.4 sec    16K iterations   90.72 μs/op
```
