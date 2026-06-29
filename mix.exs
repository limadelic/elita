defmodule Elita.MixProject do
  use Mix.Project

  def project do
    [
      app: :elita,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Chat],
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Elita.Application, []}
    ]
  end

  defp paths(:test), do: ["lib", "test/support"]
  defp paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:yaml_elixir, "~> 2.9"},
      {:ymlr, "~> 2.0"},
      {:credo, "~> 1.7", runtime: false}
    ]
  end

  defp aliases do
    [
      build: ["compile", "escript.build"],
      t: ["test --no-start"],
      lint: ["format --check-formatted", "credo --strict"]
    ]
  end
end
