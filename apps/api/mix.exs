defmodule Api.MixProject do
  use Mix.Project

  def project do
    [
      app: :api,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Api.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elita, in_umbrella: true},
      {:phoenix, "~> 1.7"},
      {:bandit, "~> 1.7"},
      {:plug, "~> 1.15"},
      {:jason, "~> 1.4"}
    ]
  end
end
