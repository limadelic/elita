defmodule Elita.App.MixProject do
  use Mix.Project

  def project do
    [
      app: :elita,
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
      mod: {Elita.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.14"},
      {:httpoison, "~> 2.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:meck, "~> 0.9", only: :test}
    ]
  end
end
