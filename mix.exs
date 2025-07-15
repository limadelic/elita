defmodule Elita.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_paths: ["test"],
      preferred_cli_env: [
        "test.e2e": :test
      ]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"}
    ]
  end

  defp aliases do
    [
      "test.e2e": ["run -e 'ExUnit.start(); Application.ensure_all_started(:elita); Code.require_file(\"test/greedy_test.exs\"); ExUnit.run()'"]
    ]
  end
end
