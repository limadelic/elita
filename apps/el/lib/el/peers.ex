defmodule El.Peers do
  import File, only: [read: 1]
  import String, only: [split: 2, trim: 1]

  def load do
    path()
    |> read()
    |> parse()
  rescue
    _ -> []
  end

  def record(peer) do
    unique = [peer | load()] |> Enum.uniq()
    persist(path(), unique)
    :ok
  rescue
    _ -> :ok
  end

  defp path do
    home = System.get_env("HOME", System.get_env("USERPROFILE", "."))
    Path.join([home, ".elita", "peers"])
  end

  defp parse({:ok, content}) do
    content
    |> split("\n")
    |> Enum.map(&trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.to_atom/1)
  end

  defp parse({:error, _}), do: []

  defp persist(file, lines) do
    File.mkdir_p!(Path.dirname(file))
    strs = lines |> Enum.map(&Atom.to_string/1)
    content = Enum.join(strs, "\n")
    File.write!(file, content)
  end
end
