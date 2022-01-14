defmodule EldapStringFilters.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :eldap_string_filters,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Docs
      name: "EldapStringFilters",
      source_url: "https://github.com/VoiSmart/eldap_string_filters",
      docs: [
        # The main page in the docs
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :eldap]
    ]
  end

  defp deps do
    [
      {:abnf_parsec, "~> 1.2", runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end
end
