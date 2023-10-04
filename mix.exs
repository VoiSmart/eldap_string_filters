defmodule EldapStringFilters.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :eldap_string_filters,
      version: "0.1.1",
      description: "An RFC4515 ldap string filter parser for eldap",
      deps: deps(),
      docs: docs(),
      elixir: "~> 1.11",
      elixirc_options: [warnings_as_errors: true],
      homepage_url: "https://github.com/VoiSmart/eldap_string_filters",
      package: package(),
      source_url: "https://github.com/VoiSmart/eldap_string_filters",
      start_permanent: Mix.env() == :prod
    ]
  end

  def application do
    [
      extra_applications: [:logger, :asn1, :eldap]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      mantainers: ["Matteo Brancaleoni"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/VoiSmart/eldap_string_filters"},
      files: files()
    ]
  end

  defp files do
    ["abnf", "lib", "mix.exs", "README*", "LICENSE*"]
  end

  defp deps do
    [
      {:nimble_parsec, "> 0.0.0", runtime: false},
      {:abnf_parsec, "~> 1.2", runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end
end
