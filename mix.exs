defmodule BinStruct.MixProject do
  use Mix.Project

  def project do
    [
      app: :bin_struct,
      version: version(),
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: ["lib"] |> maybe_add_test_elixirc_path(),
      deps: deps(),
      erlc_paths: maybe_add_test_erlc_path([]),
      package: package(),
      description: description(),
      docs: docs()
    ]
  end

  def version do
    "0.2.18"
  end

  defp maybe_add_test_elixirc_path(elixirc_paths) do
    if Mix.env() == :test do
      elixirc_paths ++
        [
          "test/support"
        ]
    else
      elixirc_paths
    end
  end

  defp maybe_add_test_erlc_path(erlc_paths) do
    if Mix.env() == :test do
      erlc_paths ++
        [
          "test/support/asn1_generated"
        ]
    else
      erlc_paths
    end
  end

  defp description() do
    "BinStruct is a library which provides you rich set of tools for parsing/encoding binaries"
  end

  defp package() do
    [
      licenses: ["MIT"],
      maintainers: ["Ridtt"],
      links: %{
        "GitHub" => "https://github.com/4ait/bin_struct",
        "Changelog" => "https://github.com/4ait/bin_struct/blob/master/CHANGELOG.md"
      }
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libgraph, "~> 0.16.0"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:benchee, "~> 1.3", only: :dev}
    ]
  end

  defp docs do
    [
      source_ref: "v#{version()}",
      main: "readme",
      # extra_section: "GUIDES",
      groups_for_modules: groups_for_modules(),
      extras: ["README.md" | Path.wildcard("pages/*/*")] ++ ["CHANGELOG.md"],
      groups_for_extras: groups_for_extras()
    ]
  end

  defp groups_for_extras do
    [
      Types: ~r/pages\/types\/.*/
    ]
  end

  defp groups_for_modules do
    [
      "Complex Types": [
        BinStruct.BuiltIn.Asn1,
        BinStruct.BuiltIn.TerminatedBinary
      ],
      "Callback helpers": [
        BinStruct.EnumValueByVariantName,
        BinStruct.EnumVariantNameByValue,
        BinStruct.FlagsReader,
        BinStruct.FlagsWriter,
        BinStruct.PrimitiveEncoder,
      ],
      "Custom types interface": [
        BinStructCustomType,
      ],
      "Options interface": [
        BinStructOptionsInterface
      ]
    ]
  end
end
