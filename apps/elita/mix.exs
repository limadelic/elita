defmodule Elita.MixProject do
  use Mix.Project

  def project do
    [
      app: :elita,
      version: "0.0.2",
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
      {:credo, "~> 1.7", runtime: false},
      {:tape, in_umbrella: true}
    ]
  end

  defp aliases do
    [
      test: [&test/1],
      t: [&test/1],
      lint: ["format --check-formatted", "credo --strict"],
      tape: [&tape/1]
    ]
  end

  defp test(_args) do
    Mix.shell().cmd("cd ../.. && TAPE=replay bundle exec cucumber")
  end

  defp tape(args) do
    Mix.shell().cmd("cd ../.. && TAPE=rec bundle exec cucumber #{Enum.join(args, " ")}")
  end
end
