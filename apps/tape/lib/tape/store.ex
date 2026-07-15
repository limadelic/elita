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
  defp normalize(_), do: []

  def add(req, response) do
    acquire(fn -> live(req, response) end)
  end

  defp live(req, response) do
    entries = load()
    mkdir_p(base())
    path = file()
    save(path, entries, req, response)
  end

  defp save(path, entries, req, response) do
    entry = [%{"q" => req, "a" => response}]
    write(path, encode!(entries ++ entry, pretty: true))
  end

  defp file do
    d = base()
    join(d, "#{get_env("CASSETTE")}.json")
  end

  defp base, do: dir(get_env("CASSETTE_DIR"))

  defp dir(nil), do: join(@app_root, "test/cassettes")
  defp dir(path), do: path
end
