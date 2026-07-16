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
    files = gather(folders)
    remote = nodes.() |> map(&remote/1)
    folders ++ files ++ remote
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
    read(folder) |> filter(&agent?/1) |> map(&file(folder, &1))
  end

  defp read(folder) do
    ls!(folder)
  rescue
    _ -> []
  end

  defp agent?(<< _::binary, ".exs" >>), do: true
  defp agent?(<< _::binary, ".md" >>), do: true
  defp agent?(_), do: false

  defp file(folder, filename) do
    n = name(filename)
    path = join(folder, filename)
    %{name: n, path: folder, file_path: path, kind: :file}
  end

  defp name(<< text::binary, ".md" >>), do: text
  defp name(<< text::binary, ".exs" >>), do: text

  defp peers do
    [node() | list()]
  end

  defp remote(node) do
    %{name: to_string(node), path: nil, kind: :node, file_path: nil}
  end
end
