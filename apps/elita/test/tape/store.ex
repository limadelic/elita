defmodule Tape.Store do
  import File, only: [write: 2, read!: 1, exists?: 1, mkdir_p: 1]
  import System, only: [get_env: 1]
  import Jason
  import Tape.Writer, only: [acquire: 1]

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
    path = cassette_file()
    mkdir_p(cassette_dir())
    entry = %{"q" => req, "a" => response}
    write(path, encode!(entries ++ [entry], pretty: true))
  end

  defp root do
    Application.app_dir(:elita) || raise "elita app not loaded"
  end

  defp cassette_file do
    Path.join(root(), "test/cassettes/#{get_env("CASSETTE")}.json")
  end

  defp cassette_dir do
    Path.join(root(), "test/cassettes")
  end
end
