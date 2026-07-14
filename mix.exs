defmodule Elita.Umbrella do
  use Mix.Project

  def project do
    [
      app: :elita_umbrella,
      version: "0.0.2",
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
      build: [&run_build/1],
      ship: "cmd bin/release"
    ]
  end

  defp run_test(_) do
    unless Mix.Task.recursing?() do
      check("cd apps/elita && mix test")
      check("cd apps/el && mix test")
    end
  end

  defp run_lint(_) do
    check("mix format --check-formatted")
    check("mix credo --strict")
    check("bundle exec rubocop")
  end

  defp run_build(_) do
    check("cd apps/el && mix escript.build")
  end

  defp check(cmd), do: confirm(Mix.shell().cmd(cmd), cmd)

  defp confirm(0, _), do: :ok
  defp confirm(_, cmd), do: raise(Mix.Error, message: "command failed: #{cmd}")

  defp deps do
    []
  end
end
