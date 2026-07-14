defmodule Agent.Jsonl.Locate do
  import File, only: [dir?: 1, ls!: 1]
  import Path, only: [join: 2]
  import System, only: [get_env: 2]
  import String, only: [replace: 3, ends_with?: 2]
  import Enum, only: [filter: 2, at: 2]
  import Agent.Jsonl.Legacy, only: [find: 0]

  def find(folder) when is_binary(folder) do
    encoded = encode(folder)
    log("watcher:folder=#{folder}\n")
    log("watcher:encoded=#{encoded}\n")
    direct(encoded)
  end

  def find(_) do
    find()
  end

  defp encode(path) do
    home = get_env("HOME", "~")
    projects = join(home, ".claude/projects")
    encoded = replace(path, "/", "-")
    join(projects, encoded)
  end

  defp direct(encoded) do
    log("watcher:target=#{encoded}\n")
    accept(encoded, dir?(encoded))
  rescue
    _ -> nil
  end

  defp accept(dir, true) do
    ls!(dir) |> filter(&ends_with?(&1, ".jsonl")) |> pick(dir)
  end

  defp accept(_, false), do: nil

  defp pick([], _), do: nil

  defp pick(files, dir) do
    path = join(dir, at(files, 0))
    log("watcher:using #{path}\n")
    path
  end

  defp log(msg) do
    :erlang.apply(:"Elixir.El.Log", :write, [msg])
  rescue
    _ -> :ok
  end
end
