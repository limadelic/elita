defmodule Int.MixProject do
  use Mix.Project

  def project do
    [
      app: :int,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:elita, path: "../.."},
      {:meck, "~> 0.9"},
      {:plug, "~> 1.14"},
      {:jason, "~> 1.4"}
    ]
  end
end
