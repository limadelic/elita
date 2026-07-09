defmodule Clock do
  import System, only: [get_env: 1]
  import String, only: [split: 2, to_integer: 1]

  # credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity

  def now do
    case get_env("TAPE") do
      "replay" -> maybe_override()
      _ -> test_time()
    end
  end

  def test_time do
    {{2025, 7, 7}, {10, 0, 0}}
  end

  defp maybe_override do
    case get_env("CLOCK") do
      nil -> test_time()
      str -> {{2025, 7, 7}, parse(str)}
    end
  end

  defp parse(str) do
    str |> split(":") |> time()
  end

  defp time([h, m]) do
    {to_integer(h), to_integer(m), 0}
  end

  defp time([h, m, s]) do
    {to_integer(h), to_integer(m), to_integer(s)}
  end
end
