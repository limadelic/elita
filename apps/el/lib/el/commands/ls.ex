defmodule El.Commands.Ls do
  @moduledoc "Lists agents in the current folder with their registration status."

  import IO, only: [puts: 1]
  import File, only: [ls!: 1]
  import Enum, only: [map: 2, sort_by: 2, reject: 2, join: 2]
  import String, only: [starts_with?: 2]

  def execute(opts \\ []) do
    cwd = Keyword.get(opts, :cwd, File.cwd!())
    render(cwd) |> puts()
  end

  def remote(opts \\ []) do
    cwd = Keyword.get(opts, :cwd, File.cwd!())
    render(cwd)
  end

  defp render(cwd) do
    build(cwd) |> format_output()
  end

  defp format_output([]) do
    "no agents"
  end

  defp format_output(entries) do
    entries |> map(&format/1) |> join("\n")
  end

  defp build(path) do
    path
    |> ls!()
    |> reject(&hidden/1)
    |> map(&entry(path, &1))
    |> sort_by(& &1.name)
  end

  defp hidden(name) do
    starts_with?(name, ".")
  end

  defp entry(path, name) do
    full = Path.join(path, name)
    %{name: name, path: full, kind: guess_kind(full)}
  end

  defp guess_kind(path) do
    File.dir?(path) |> choose_kind()
  end

  defp choose_kind(true), do: :folder
  defp choose_kind(false), do: :file

  defp format(entry) do
    "#{entry.name} #{kind_label(entry.kind)} #{status(entry.name)}"
  end

  defp status(name) do
    Registry.lookup(ElitaRegistry, name) |> map_status()
  end

  defp map_status([_ | _]), do: "active"
  defp map_status([]), do: "asleep"

  defp kind_label(:file), do: "file"
  defp kind_label(:folder), do: "folder"
end
