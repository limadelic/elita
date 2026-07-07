defmodule El.Commands.Ls do
  @moduledoc "Lists agents in the current folder with their registration status."

  import IO, only: [puts: 1]
  import Enum, only: [map: 2, sort_by: 2, filter: 2, join: 2]
  import El.Commands.Address.World, only: [build: 0, cwd: 0]
  import Resolver, only: [normalize: 2, glob: 2]

  def execute(opts \\ []) do
    path = Keyword.get(opts, :path, nil)
    render(path) |> puts()
  end

  def remote(opts \\ []) do
    path = Keyword.get(opts, :path, nil)
    render(path)
  end

  defp render(path) do
    world = build()
    here = cwd()
    target = normalize(path, here)
    world |> entries(target) |> sort_by(& &1.name) |> format_output()
  end

  defp entries(world, nil), do: world
  defp entries(world, target) do
    world |> filter(&match_path?(&1, target))
  end

  defp match_path?(%{path: p}, t) when p == t, do: true
  defp match_path?(%{path: p}, t), do: glob(p, t)
  defp match_path?(_, _), do: false

  defp format_output([]) do
    "no agents"
  end

  defp format_output(entries) do
    entries |> map(&format/1) |> join("\n")
  end

  defp format(entry) do
    "#{entry.name} #{kind_label(entry.kind)} #{status(entry.name)}"
  end

  defp status(name) do
    normalized = String.downcase(to_string(name))
    Registry.lookup(ElitaRegistry, normalized) |> map_status()
  end

  defp map_status([_ | _]), do: "active"
  defp map_status([]), do: "asleep"

  defp kind_label(:file), do: "file"
  defp kind_label(:folder), do: "folder"
end
