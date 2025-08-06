defmodule Elita.MixProject do
  use Mix.Project

  def project do
    [
      app: :elita,
      version: "0.1.0",
      elixir: "~> 1.18",
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:yaml_elixir, "~> 2.9"}
    ]
  end

  defp aliases do
    [
      build: ["compile", "escript.build"]
    ]
  end
end
