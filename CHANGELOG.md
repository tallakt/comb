# Changelog

## 0.3.0

### Added

- `count_partitions/1` and `nth_partition/2`
- `count_selections/2` and `nth_selection/3`
- `count_permuted_combinations/2` and `nth_permuted_combination/3`
- `count_cartesian_product/1` and `nth_cartesian_product/2`
- `combinations_with_replacement/2`, `count_combinations_with_replacement/2` and
  `nth_combination_with_replacement/3`
- `SComb.Sequence`, the type of what `permutations/1`, `combinations/2`,
  `subsets/1`, `selections/2`, `partitions/1`, `combinations_with_replacement/2`,
  `permuted_combinations/2` and `cartesian_product/1` return. It is an
  `Enumerable` that knows its size and finds an element by index, so
  `Enum.count/1`, `Enum.at/2`, `Enum.slice/2`, `Enum.random/1` and similar do
  not generate the elements before it. Inputs of more than 2000 elements, or
  200 for partitions, are streamed as before

### Changed

- The functions above return a `SComb.Sequence` rather than a `Stream` or a
  list. They are still enumerable, but code that relies on the exact type of
  the result, for example `is_list/1`, will no longer work
- `combinations/2` returns the combinations in colexicographic order, by the
  last value they hold, so `combinations(1..4, 2)` returns
  `[[1, 2], [1, 3], [2, 3], [1, 4], [2, 4], [3, 4]]`. Consecutive combinations
  then share the end of their lists, which makes generating them about four
  times faster. `subsets/1` returns the subsets of each size in this order,
  and `combinations_with_replacement/2` and `permuted_combinations/2` follow
  it, as do the `nth_*` functions of all of these
- `partitions/1` returns the partitions in a different order, and the blocks
  of a partition are ordered by the last element they hold:
  `nth_partition(1..3, 2)` is `[[2], [1, 3]]` where it was `[[1, 3], [2]]`.
  Consecutive partitions then share the end of their lists, which makes
  generating them somewhat faster
- The `:min` and `:max` limits of `partitions/2` are applied while the
  partitions are generated, so `partitions(1..40, min: 39)` does not go
  through every partition of 40 elements

## 0.2.0

### Added

- `permuted_combinations/2`, every permutation of every combination of `k`
  elements
- `partitions/2` accepts `:min` and `:max` options limiting the number of
  blocks, as in the Clojure `math.combinatorics` library

### Fixed

- The `nth_*` functions raised a `KeyError` instead of
  `Enum.OutOfBoundsError` for an index out of bounds

## 0.1.0

Changes since 0.0.2:

### Added

- `cartesian_product/1`, the cartesian product of any number of enumerables
- `nth_subset/2`
- `SComb.Math.binomial/2` and `SComb.Math.multinomial/1`
- Package metadata and documentation for publishing on Hex

### Changed

- Renamed from Comb to SComb, for streaming combinatorics: the package is now
  `scomb` and the modules `SComb` and `SComb.Math`, as the name `comb` is taken
  on Hex
- Every function now has a dedicated algorithm, instead of filtering the
  results of a naive one:
  - `permutations/1` uses a successor algorithm that handles repeated elements
    directly, rather than generating and discarding duplicates
  - `count_combinations/2`, `count_subsets/1`, `nth_combination/3`,
    `nth_subset/2`, `nth_permutation/2`, `drop_permutations/2` and
    `permutation_index/1` compute their result without generating the elements
    before it
  - `combinations/2`, `subsets/1`, `partitions/1` and `selections/2` are
    generated lazily
- Repeated elements no longer need to be next to each other:
  `combinations([1, 2, 1], 2)` returns `[[1, 2], [1, 1]]` rather than
  `[[1, 2], [1, 1], [2, 1]]`. Where repeated elements are not next to each
  other, results may come in a different order than before
- `selections/2` selects each distinct element once, so
  `selections([1, 1], 1)` returns `[[1]]`
- The partitions of an input with repeated elements come in a different order,
  and their blocks are ordered differently: `partitions([1, 1, 2])` now returns
  `[[1, 2], [1]]` where it returned `[[1], [1, 2]]`. The partitions of distinct
  elements are unchanged up to 3 elements
- The `nth_*` functions accept a negative index, counting from the end
- `SComb.Math.factorial/1` raises for negative numbers rather than never
  returning

### Removed

- `Comb.TablePermutations` and `Comb.ListAnalyzer`, which were internal
- The naive reference implementations and the benchmark task, now
  `scomb.benchmark`, moved to `bench/`, and are no longer part of the package
