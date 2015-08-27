Permutations
============

This repo is just for testing various versions of permutations and combinations
of an Enumerable in Elixir

## Current benchmark

```
    $ mix benchmark
    Testing permutation
    *** &Permutations.Naive.permutation/1 ***
    1.1 sec     2K iterations   549.1 μs/op

    *** &Permutations.TallakEnum.permutation/1 ***
    2.1 sec     1K iterations   2077.22 μs/op

    *** #Function<2.27032019/1 in Mix.Tasks.Benchmark.run/1> ***
    1.6 sec     63 iterations   26730.1 μs/op

    *** #Function<1.27032019/1 in Mix.Tasks.Benchmark.run/1> ***
    1.0 sec    511 iterations   2113.49 μs/op

    Testing combination
    *** &Permutations.Wless1.combinations/2 ***
    1.3 sec   131K iterations   10.37 μs/op
```
     
