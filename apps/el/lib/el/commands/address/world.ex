defmodule El.Commands.Address.World do
  import Agent.Config, only: [load: 0]
  import El.Standpoint, only: [get: 0]

  def build(nodes \\ &peers/0) do
    folders = load() |> Enum.map(&entry/1)
    files = Enum.flat_map(folders, &scan/1)
    unique_files = Enum.uniq_by(files, &{&1.name, &1.path})
    remote = nodes.() |> Enum.map(&remote/1)
    folders ++ unique_files ++ remote
  end

  def cwd do
    get()
  end

  defp entry({name, folder}) do
    folder = Path.expand(folder)
    self = check(folder)
    %{name: Atom.to_string(name), path: folder, kind: :folder, file_path: self}
  end

  defp check(folder) do
    agent = Path.join(folder, "agent.md")
    pick(File.exists?(agent), agent)
  end

  defp pick(true, path), do: path
  defp pick(false, _path), do: nil

  defp scan(%{path: folder}) do
    File.ls!(folder)
    |> Enum.filter(&String.ends_with?(&1, ".exs"))
    |> Enum.map(&file(folder, &1))
  rescue
    _ -> []
  end

  defp file(folder, filename) do
    name = String.trim_trailing(filename, ".exs")
    file_path = Path.join(folder, filename)
    %{name: name, path: folder, file_path: file_path, kind: :file}
  end

  defp peers do
    [Node.self() | Node.list()]
  end

  defp remote(node) do
    %{name: Atom.to_string(node), path: nil, kind: :node, file_path: nil}
  end
end
