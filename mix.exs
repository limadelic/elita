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
    cmd1 = "cd apps/elita && mix test"
    cmd2 = "cd apps/el && mix test"
    Mix.shell().cmd(cmd1)
    Mix.shell().cmd(cmd2)
  end

  defp run_lint(_) do
    cmd = "cd apps/elita && mix lint"
    Mix.shell().cmd(cmd)
  end

  defp run_build(_) do
    cmd = "cd apps/el && mix escript.build"
    Mix.shell().cmd(cmd)
  end

  defp deps do
    []
  end
end
