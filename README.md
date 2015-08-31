Comb
====

This repo is just for testing various versions of permutations and combinations
of an Enumerable in Elixir

## Current benchmark

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

