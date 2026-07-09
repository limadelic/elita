defmodule El.Commands.Address.World do
  import Agent.Config, only: [load: 0]
  import El.Standpoint, only: [get: 0]
  import Enum, only: [map: 2, flat_map: 2, uniq_by: 2, filter: 2]
  import File, only: [exists?: 1, ls!: 1]
  import Path, only: [expand: 1, join: 2]
  import String, only: [ends_with?: 2, trim_trailing: 2]
  import Node, only: [list: 0]

  def build(nodes \\ &peers/0) do
    folders = load() |> map(&entry/1)
    unique_files = gather(folders)
    remote = nodes.() |> map(&remote/1)
    folders ++ unique_files ++ remote
  end

  defp gather(folders) do
    flat_map(folders, &scan/1) |> uniq_by(&{&1.name, &1.path})
  end

  def cwd do
    get()
  end

  defp entry({name, folder}) do
    folder = expand(folder)
    self = check(folder)
    %{name: to_string(name), path: folder, kind: :folder, file_path: self}
  end

  defp check(folder) do
    agent = join(folder, "agent.md")
    pick(exists?(agent), agent)
  end

  defp pick(true, path), do: path
  defp pick(false, _path), do: nil

  defp scan(%{path: folder}) do
    ls!(folder) |> filter(&ends_with?(&1, ".exs")) |> map(&file(folder, &1))
  rescue
    _ -> []
  end

  defp file(folder, filename) do
    name = trim_trailing(filename, ".exs")
    file_path = join(folder, filename)
    %{name: name, path: folder, file_path: file_path, kind: :file}
  end

  defp peers do
    [Node.self() | list()]
  end

  defp remote(node) do
    %{name: to_string(node), path: nil, kind: :node, file_path: nil}
  end
end
