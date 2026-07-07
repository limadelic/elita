defmodule El.Commands.Address.World do
  import Agent.Config, only: [load: 0]

  def build do
    folders = load() |> Enum.map(&entry/1)
    files = Enum.flat_map(folders, &scan/1)
    unique_files = Enum.uniq_by(files, &{&1.name, &1.path})
    folders ++ unique_files
  end

  def cwd do
    File.cwd!() |> trim()
  end

  defp entry({name, folder}) do
    %{name: Atom.to_string(name), path: Path.expand(folder), kind: :folder}
  end

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

  defp trim("/private" <> rest), do: rest
  defp trim(path), do: path
end
