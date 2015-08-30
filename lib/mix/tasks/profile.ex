if Mix.env == :dev do
  defmodule Mix.Tasks.Profile do
    @shortdoc "Profile using ExProf"
    use Mix.Task
    import ExProf.Macro

    def run(_mix_args) do
      profile do: Comb.LazyPermutations.permutation(1..6) |> Stream.run
      #profile do: Comb.SJT.permutation(1..6) |> Stream.run
    end
  end
end
