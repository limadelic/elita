defmodule El.Commands.Ls do
  import IO, only: [puts: 1]
  import File, only: [ls!: 1]
  import Enum, only: [map: 2, sort_by: 2, each: 2]
  import Agent.Registry, only: [lookup: 1]

  def execute(opts \\ []) do
    cwd = Keyword.get(opts, :cwd, File.cwd!())
    build(cwd) |> show()
  end

  defp build(path) do
    path
    |> ls!()
    |> map(&entry(path, &1))
    |> sort_by(& &1.name)
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

  defp show([]), do: puts("no agents")

  defp show(entries) do
    entries |> map(&format/1) |> each(&puts/1)
  end

  defp format(entry) do
    "#{entry.name} #{kind_label(entry.kind)} #{status(entry.name)}"
  end

  defp status(name) do
    lookup(name) |> map_status()
  end

  defp map_status({:ok, _}), do: "active"
  defp map_status({:error, _}), do: "asleep"

  defp kind_label(:file), do: "file"
  defp kind_label(:folder), do: "folder"
end
