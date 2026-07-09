defmodule El.Shipped do
  import System, only: [get_env: 1, put_env: 2]
  import Path, only: [join: 2, dirname: 1]

  def setup, do: maybe_set_defaults(get_env("MIX_ENV"), get_env("CASSETTE"))

  defp maybe_set_defaults("test", _), do: :ok
  defp maybe_set_defaults(_, cassette) when cassette != nil, do: :ok
  defp maybe_set_defaults(_, _), do: set_defaults()

  defp set_defaults do
    put_env("CASSETTE", "el")
    put_env("CASSETTE_DIR", shipped_dir())
    put_env("TAPE_ON_MISS", "live")
  end

  defp shipped_dir do
    __DIR__ |> dirname() |> dirname() |> join("cassettes")
  end
end
