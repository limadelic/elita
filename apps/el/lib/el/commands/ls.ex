defmodule El.Commands.Ls do
  @moduledoc "Lists agents in the current folder with their registration status."

  import El.Commands.Address.World, only: [build: 0, cwd: 0]
  import Enum, only: [map: 2, sort_by: 2, filter: 2, join: 2, any?: 2]
  import IO, only: [puts: 1]
  import Keyword, only: [get: 2]
  import Registry, only: [lookup: 2, select: 2]
  import Glob, only: [hits?: 2]
  import Resolver, only: [normalize: 2]
  import String, only: [downcase: 1]

  def ls(opts \\ []) do
    path = get(opts, :path)
    render(path) |> puts()
  end

  def remote(opts \\ []) do
    path = get(opts, :path)
    render(path)
  end

  defp render("//") do
    build()
    |> filter(&(&1.kind == :node))
    |> sort_by(& &1.name)
    |> show()
  end

  defp render(path) do
    target = normalize(path, cwd())
    world = build() |> filter(&(&1.kind != :node))
    visible = entries(world, target)
    (visible ++ harvest(visible)) |> sort_by(& &1.name) |> show()
  end

  defp entries(world, nil), do: world

  defp entries(world, target) do
    world |> filter(&fits?(&1, target))
  end

  defp fits?(%{path: p}, t) when p == t, do: true
  defp fits?(%{path: p}, t), do: hits?(p, t)
  defp fits?(_, _), do: false

  defp show([]) do
    "no agents"
  end

  defp show(entries) do
    entries |> map(&format/1) |> join("\n")
  end

  defp format(%{kind: :node} = entry) do
    "#{entry.name} #{label(entry.kind)}"
  end

  defp format(entry) do
    "#{entry.name} #{label(entry.kind)} #{status(entry.name)}"
  end

  defp status(name) do
    normalized = downcase(to_string(name))
    lookup(ElitaRegistry, normalized) |> flag()
  end

  defp flag([_ | _]), do: "active"
  defp flag([]), do: "asleep"

  defp harvest(visible) do
    names = map(visible, & &1.name)
    headless(names) |> map(&entry/1)
  end

  defp headless(names) do
    ElitaRegistry
    |> select([{{:"$1", :_, %{kind: :headless}}, [], [:"$1"]}])
    |> filter(&absent?(names, &1))
  end

  defp absent?(list, name) do
    !any?(list, fn n ->
      downcase(to_string(n)) == downcase(to_string(name))
    end)
  end

  defp entry(name) do
    %{name: to_string(name), path: nil, kind: :session}
  end

  defp label(:file), do: "file"
  defp label(:folder), do: "folder"
  defp label(:session), do: "session"
  defp label(:node), do: "node"
end
