defmodule SComb.MixProject do
  use Mix.Project

  @version "0.2.0"
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
      source_url: @source_url,
      dialyzer: [plt_local_path: "priv/plts", plt_core_path: "priv/plts", plt_add_apps: [:mix]]
    ]
  end

  # The naive reference implementation and the benchmark task are only needed
  # for development
  defp elixirc_paths(:prod), do: ["lib"]
  defp elixirc_paths(_), do: ["lib", "bench"]

  defp deps do
    [
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 1.0", only: :test}
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
      links: %{"GitHub" => @source_url, "Changelog" => @source_url <> "/blob/master/CHANGELOG.md"},
      files: ~w(lib mix.exs README.md CHANGELOG.md LICENSE .formatter.exs)
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
