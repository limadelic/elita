defmodule Agent.Jsonl.Legacy do
  import File, only: [ls!: 1, dir?: 1, stat!: 1]
  import Path, only: [join: 2]
  import System, only: [get_env: 2]
  import String, only: [ends_with?: 2]
  import Enum, only: [filter: 2, map: 2, max_by: 3, count: 1]

  def find do
    get_env("HOME", "~") |> setup()
  rescue
    _ -> nil
  end

  defp setup(home) do
    projects = join(home, ".claude/projects")
    log("watcher:home=#{home}\n")
    log("watcher:projects=#{projects}\n")
    browse(projects)
  end

  defp browse(root) do
    ready(dir?(root), root)
  end

  defp ready(true, root) do
    collect(root) |> latest()
  end

  defp ready(false, _), do: nil

  defp collect(root) do
    dirs = ls!(root) |> map(&join(root, &1)) |> filter(&dir?/1)
    log("watcher:found #{count(dirs)} dirs\n")
    dirs
  end

  defp latest(dirs) do
    max_by(dirs, &mtime/1, fn -> nil end) |> file()
  end

  defp file(nil), do: nil

  defp file(dir) do
    log("watcher:scanning dir=#{dir}\n")
    jsons(dir)
  end

  defp jsons(dir) do
    files = ls!(dir) |> filter(&ends_with?(&1, ".jsonl"))
    log("watcher:found #{count(files)} jsonl\n")
    best(files, dir)
  end

  defp best(files, dir) do
    max_by(files, &mtime(&1, dir), fn -> nil end) |> emit(dir)
  end

  defp emit(nil, _) do
    log("watcher:no file\n")
    nil
  end

  defp emit(name, dir) do
    path = join(dir, name)
    log("watcher:using #{path}\n")
    path
  end

  defp mtime(path) do
    stat!(path).mtime
  end

  defp mtime(name, dir) do
    stat!(join(dir, name)).mtime
  end

  defp log(msg) do
    :erlang.apply(:"Elixir.Matrix.Log", :write, [msg])
  rescue
    _ -> :ok
  end
end
