defmodule Agent.Jsonl do
  import File, only: [exists?: 1, read!: 1, ls!: 1, dir?: 1]
  import Path, only: [join: 2]
  import System, only: [get_env: 2]
  import String, only: [split: 2, ends_with?: 2]
  import Enum, only: [drop: 2, with_index: 2, find_value: 3, max_by: 3, filter: 2, map: 2]

  def find(question, pos) do
    path() |> load(question, pos)
  end

  defp load(nil, _, _), do: :wait

  defp load(p, q, pos) do
    if exists?(p) do
      p |> read!() |> split("\n") |> scan(q, pos)
    else
      :wait
    end
  catch
    :exit, _ -> :wait
    _, _ -> :wait
  end

  defp scan(lines, q, pos) do
    lines |> drop(pos) |> with_index(pos) |> rows(q)
  end

  defp rows(indexed, q) do
    find_value(indexed, {:continue, Enum.count(indexed)}, &row(&1, q))
  end

  defp row({line, _}, _) when byte_size(line) < 10, do: nil

  defp row({line, _}, _) do
    line |> Jason.decode() |> type()
  rescue
    _ -> nil
  end

  defp type({:ok, %{"type" => "assistant", "message" => %{"content" => c}}}),
    do: text(c)

  defp type({:ok, %{"type" => "assistant", "content" => c}}), do: text(c)

  defp type(_), do: nil

  defp text(c) when is_list(c) do
    t = find_value(c, "", &pick/1)
    if byte_size(t) > 0, do: {:found, t}, else: nil
  end

  defp text(_), do: nil

  defp pick(%{"text" => t}) when is_binary(t), do: t
  defp pick(%{"type" => "text", "text" => t}), do: t
  defp pick(_), do: nil

  defp path do
    home = get_env("HOME", "~")
    projects = join(home, ".claude/projects")
    log("watcher:home=#{home}\n")
    log("watcher:projects=#{projects}\n")
    if dir?(projects) do
      dirs = ls!(projects) |> map(&join(projects, &1)) |> filter(&dir?/1)
      log("watcher:found #{Enum.count(dirs)} dirs\n")
      dirs |> sort()
    else
      log("watcher:no projects dir\n")
      nil
    end
  rescue
    e -> Log.write("watcher: error=#{inspect(e)}\n"); nil
  end

  defp sort(dirs) do
    max_by(dirs, &mtime/1, fn -> nil end) |> pick_dir()
  end

  defp pick_dir(nil), do: nil

  defp pick_dir(dir) do
    log("watcher:scanning dir=#{dir}\n")
    files = ls!(dir) |> filter(&ends_with?(&1, ".jsonl"))
    log("watcher:found #{Enum.count(files)} jsonl\n")
    max_by(files, &mtime_at(&1, dir), fn -> nil end)
    |> case do
      nil ->
        log("watcher:no file\n")
        nil
      file ->
        p = join(dir, file)
        log("watcher:using #{p}\n")
        p
    end
  end

  defp mtime(path) do
    File.stat!(path).mtime
  end

  defp mtime_at(file, dir) do
    File.stat!(join(dir, file)).mtime
  end

  defp log(msg) do
    :erlang.apply(:"Elixir.El.Log", :write, [msg])
  rescue
    _ -> :ok
  end
end
