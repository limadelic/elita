defmodule Tape.Store do
  import File, only: [write: 2, read!: 1, exists?: 1, mkdir_p: 1]
  import Path, only: [expand: 2, join: 2]
  import Jason
  import System, only: [get_env: 1]
  import Tape.Writer, only: [acquire: 1]

  @app_root expand("../..", __DIR__)

  def read do
    path = file()
    get(path, exists?(path))
  end

  defp get(path, true), do: {:new_format, decode!(read!(path))}
  defp get(_path, false), do: {:new_format, []}

  def load do
    open(read())
  end

  defp open({:new_format, e}), do: normalize(e)

  defp normalize(list) when is_list(list), do: list
  defp normalize(map) when is_map(map), do: Map.get(map, "tape", [])
  defp normalize(_), do: []

  def add(req, response) do
    acquire(fn -> live(req, response) end)
  end

  defp live(req, response) do
    data = read()
    mkdir_p(base())
    path = file()
    save(path, data, req, response)
  end

  defp save(path, {:new_format, map}, req, response) when is_map(map) do
    entry = %{"q" => req, "a" => response}
    payload = merge(map, entry)
    write(path, encode!(payload, pretty: true))
  end

  defp save(path, {:new_format, list}, req, response) when is_list(list) do
    payload = convert(list, req, response)
    write(path, encode!(payload, pretty: true))
  end

  defp merge(map, entry) do
    tape = Map.get(map, "tape", [])
    screens = Map.get(map, "screens", %{})
    %{"screens" => screens, "tape" => tape ++ [entry]}
  end

  defp convert(list, req, response) do
    entry = %{"q" => req, "a" => response}
    %{"screens" => %{}, "tape" => list ++ [entry]}
  end

  defp file do
    d = base()
    join(d, "#{get_env("CASSETTE")}.json")
  end

  defp base, do: dir(get_env("CASSETTE_DIR"))

  defp dir(nil), do: join(@app_root, "test/cassettes")
  defp dir(path), do: path
end
