defmodule Comb.MixProject do
  use Mix.Project

  def project do
    [
      app: :comb,
      version: "0.0.2",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end
end
