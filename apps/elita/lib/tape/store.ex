defmodule Tape.Store do
  import File, only: [write: 2, read!: 1, exists?: 1, mkdir_p: 1]
  import Path, only: [expand: 2, join: 2]
  import Jason
  import System, only: [get_env: 1]
  import Tape.Writer, only: [acquire: 1]

  @app_root expand("../..", __DIR__)

  def read_cassette do
    path = cassette_file()
    read_cassette_at(path, exists?(path))
  end

  defp read_cassette_at(path, true), do: {:new_format, decode!(read!(path))}
  defp read_cassette_at(_path, false), do: {:new_format, []}

  def load_entries do
    load_entries_from(read_cassette())
  end

  defp load_entries_from({:new_format, e}), do: normalize(e)

  defp normalize(list) when is_list(list), do: list
  defp normalize(_), do: []

  def append_live(req, response) do
    acquire(fn -> live(req, response) end)
  end

  defp live(req, response) do
    entries = load_entries()
    mkdir_p(cassette_dir())
    path = cassette_file()
    save(path, entries, req, response)
  end

  defp save(path, entries, req, response) do
    entry = [%{"q" => req, "a" => response}]
    write(path, encode!(entries ++ entry, pretty: true))
  end

  defp cassette_file do
    dir = cassette_dir()
    join(dir, "#{get_env("CASSETTE")}.json")
  end

  defp cassette_dir do
    get_env("CASSETTE_DIR") || join(@app_root, "test/cassettes")
  end
end
