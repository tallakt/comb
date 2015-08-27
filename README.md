Permutations
============

This repo is just for testing various versions of permutations and combinations
of an Enumerable in Elixir

## Current benchmark

```
    $ mix benchmark
    Testing permutation
    *** &Permutations.Naive.permutation/1 ***
    1.2 sec     2K iterations   595.02 μs/op

    *** &Permutations.TallakEnum.permutation/1 ***
    1.1 sec    511 iterations   2203.51 μs/op

    *** #Function<2.108733102/1 in Mix.Tasks.Benchmark.run/1> ***
    1.7 sec     63 iterations   27222.16 μs/op

    *** #Function<1.108733102/1 in Mix.Tasks.Benchmark.run/1> ***
    1.0 sec    511 iterations   2048.91 μs/op

    Testing combination
    *** &Permutations.Wless1.combinations/2 ***
    1.2 sec   131K iterations   9.4 μs/op

    *** &Permutations.Wless1.combinations2/2 ***
    1.0 sec   131K iterations   7.74 μs/op
```
