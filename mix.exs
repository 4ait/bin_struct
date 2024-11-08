defmodule BinStruct.MixProject do
  use Mix.Project

  def project do
    [
      app: :bin_struct,
      version: "0.2.1",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: ["lib"] |> maybe_add_test_elixirc_path(),
      deps: deps(),
      erlc_paths: maybe_add_test_erlc_path([])
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

  defp maybe_add_test_erlc_path(erlc_paths) do

    if Mix.env() == :test do
      erlc_paths ++ [
        "test/support/asn1_generated"
      ]
    else
      erlc_paths
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
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:benchee, "~> 1.3", only: :dev},
    ]
  end
end
