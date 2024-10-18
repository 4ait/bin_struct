defmodule BinStruct.MixProject do
  use Mix.Project

  def project do
    [
      app: :bin_struct,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: ["lib"] |> maybe_add_test_elixirc_path(),
      deps: deps()
    ]
  end

  defp maybe_add_test_elixirc_path(elixirc_paths) do

    if Mix.env() == :test do
      elixirc_paths ++ [
        "test/support"
      ]
    else
      elixirc_paths
    end

  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ssl]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libgraph, "~> 0.16.0"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
