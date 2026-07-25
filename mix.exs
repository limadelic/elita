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
      cukes: [&run_cukes/1],
      build: [&run_build/1],
      ship: "cmd bin/release"
    ]
  end

  defp run_test(_) do
    unless Mix.Task.recursing?() do
      check("cd apps/elita && mix test")
      check("cd apps/el && mix test")
      check("cd apps/matrix && mix test")
    end
  end

  defp run_lint(_) do
    check("mix format --check-formatted")
    check("cd apps/el && mix format --check-formatted")
    check("cd apps/elita && mix format --check-formatted")
    check("cd apps/matrix && mix format --check-formatted")
    check("mix credo --strict")
    check("bundle exec rubocop")
    check("npm run fmt:check")
  end

  defp run_cukes(args) do
    extra = args |> Enum.join(" ") |> String.trim()
    files = untagged_features()
    files_arg = if Enum.any?(files), do: " #{Enum.join(files, " ")}", else: ""
    cmd = "bundle exec cucumber --profile default" <> files_arg <> (if extra != "", do: " #{extra}", else: "")
    check(cmd)
  end

  defp untagged_features do
    "features/**/*.feature"
    |> Path.wildcard()
    |> Enum.filter(fn f -> !has_tag?(f, "@wip") and !has_tag?(f, "@live") end)
    |> Enum.sort()
  end

  defp has_tag?(file, tag) do
    file
    |> File.read!()
    |> String.contains?(tag)
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
