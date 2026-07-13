defmodule El.MixProject do
  use Mix.Project

  def project do
    [
      app: :el,
      version: "0.0.2",
      elixir: "~> 1.18",
      elixirc_paths: paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: El.CLI, emu_args: ""],
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
      test: [&test/1],
      lint: ["format --check-formatted", "credo --strict"]
    ]
  end

  defp test(_args) do
    check("mix test")
  end

  defp check(cmd) do
    case Mix.shell().cmd(cmd) do
      0 -> :ok
      _ -> raise Mix.Error, "command failed: #{cmd}"
    end
  end

  def application do
    [
      extra_applications: [:logger, :tools]
    ]
  end

  defp deps do
    [
      {:elita, in_umbrella: true}
    ]
  end
end
