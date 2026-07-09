defmodule Elita.Umbrella do
  use Mix.Project

  def project do
    [
      app: :elita_umbrella,
      version: "0.1.0",
      elixir: "~> 1.18",
      apps_path: "apps",
      config_path: "config/config.exs",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      test: [&run_test/1],
      lint: [&run_lint/1],
      build: [&run_build/1]
    ]
  end

  defp run_test(_) do
    check("cd apps/elita && mix test")
    check("cd apps/el && mix test")
  end

  defp run_lint(_) do
    check("cd apps/elita && mix lint")
    check("cd apps/el && mix lint")
    check("cd apps/tape && mix lint")
  end

  defp run_build(_) do
    check("cd apps/el && mix escript.build")
  end

  defp check(cmd) do
    case Mix.shell().cmd(cmd) do
      0 -> :ok
      _ -> raise Mix.Error, "command failed: #{cmd}"
    end
  end

  defp deps do
    []
  end
end
