Permutations
============

This repo is just for testing various versions of permutations and combinations
of an Enumerable in Elixir

## Current benchmark

```
Testing permutation
-- naive
*** #Function<1.30592332/0 in Mix.Tasks.Benchmark.run/1> ***
1.0 sec      7 iterations   156350.72 μs/op

-- tallaks enum impl
*** #Function<2.30592332/0 in Mix.Tasks.Benchmark.run/1> ***
1.1 sec      3 iterations   378996.34 μs/op

-- tallaks stream impl
*** #Function<3.30592332/0 in Mix.Tasks.Benchmark.run/1> ***
2.3 sec      1 iterations   2333066.0 μs/op

-- tallaks maps impl
*** #Function<4.30592332/0 in Mix.Tasks.Benchmark.run/1> ***
1.3 sec      1 iterations   1321631.0 μs/op

-- SJT
*** #Function<5.30592332/0 in Mix.Tasks.Benchmark.run/1> ***
1.2 sec      3 iterations   400397.34 μs/op

-- LazyPermutations
*** #Function<6.30592332/0 in Mix.Tasks.Benchmark.run/1> ***
1.6 sec      7 iterations   237121.43 μs/op

Testing combination
-- Wless1 Optimized
*** #Function<7.30592332/0 in Mix.Tasks.Benchmark.run/1> ***
1.5 sec    32K iterations   46.23 μs/op

-- Wless1 Naive
*** #Function<8.30592332/0 in Mix.Tasks.Benchmark.run/1> ***
1.5 sec    16K iterations   92.27 μs/op
```
