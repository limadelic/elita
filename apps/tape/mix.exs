defmodule Tape.MixProject do
  use Mix.Project

  def project do
    [
      app: :tape,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      compilers: [:yecc, :leex, :erlang, :elixir, :app],
      elixirc_options: [warnings_as_errors: true]
    ]
  end

  defp paths(:test), do: ["lib", "test/support"]
  defp paths(_), do: ["lib"]

  defp aliases do
    [
      lint: ["format --check-formatted", "credo --strict"]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:credo, "~> 1.7", runtime: false}
    ]
  end
end
