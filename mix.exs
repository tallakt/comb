defmodule SComb.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/tallakt/scomb"

  def project do
    [
      app: :scomb,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: @source_url
    ]
  end

  # The naive reference implementation and the benchmark task are only needed
  # for development
  defp elixirc_paths(:prod), do: ["lib"]
  defp elixirc_paths(_), do: ["lib", "bench"]

  defp deps do
    [
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Streaming combinatorics: permutations, combinations, subsets, " <>
      "selections, partitions and cartesian products, generated lazily and " <>
      "handling repeated elements"
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "SComb",
      source_ref: "v#{@version}",
      extras: ["CHANGELOG.md"]
    ]
  end
end
