defmodule Matrix.Movie.Load do
  @moduledoc false
  import System, only: [get_env: 1]
  import File, only: [read: 1]
  import Map, only: [get: 2, get: 3, has_key?: 2]
  import Path, only: [join: 2]
  import Enum, only: [map: 2]
  import Base, only: [decode64: 1]
  import Jason, only: [decode!: 1]

  def run(name) do
    load() |> get("movies", %{}) |> get(to_string(name)) |> map(&extract/1)
  end

  def exists?(name) do
    load() |> get("movies", %{}) |> has_key?(to_string(name))
  end

  defp load do
    file() |> read() |> content()
  end

  defp content({:ok, c}), do: decode!(c)
  defp content({:error, _}), do: %{}

  defp extract(encoded) do
    {:ok, decoded} = decode64(encoded)
    decoded
  end

  defp file do
    cassette = get_env("CASSETTE")
    dir = dir()
    join(dir, "#{cassette}.json")
  end

  defp dir do
    get_env("CASSETTE_DIR") |> pick()
  end

  defp pick(nil), do: "test/cassettes"
  defp pick(val), do: val
end
