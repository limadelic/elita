defmodule El.Peers do
  import Enum, only: [join: 2, map: 2, reject: 2, uniq: 1]
  import File, only: [mkdir_p!: 1, read: 1, write!: 2]
  import Path, only: [dirname: 1]
  import String, only: [split: 2, to_atom: 1, trim: 1]
  import El.Run, only: [file: 0]

  def load do
    path() |> read() |> parse()
  rescue
    _ -> []
  end

  def record(peer) do
    unique = [peer | load()] |> uniq()
    store(path(), unique)
  rescue
    _ -> :ok
  end

  defp path do
    file()
  end

  defp store(file, lines) do
    mkdir_p!(dirname(file))
    write!(file, lines |> map(&to_string/1) |> join("\n"))
  end

  defp parse({:ok, content}) do
    content |> split("\n") |> clean()
  end

  defp parse({:error, _}), do: []

  defp clean(lines) do
    lines |> map(&trim/1) |> reject(&(&1 == "")) |> map(&to_atom/1)
  end
end
