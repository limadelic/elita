defmodule El.Sessions do
  import File, only: [ls: 1, read!: 1, stat!: 1]
  import Path, only: [expand: 1, join: 2]
  import String, only: [starts_with?: 2, ends_with?: 2, split: 2, replace: 3]
  import Enum, only: [filter: 2, sort_by: 2, at: 2, map: 2, sort: 1, reduce: 3]
  import List, only: [last: 1]

  def log(""), do: ""

  def log(agent) do
    expand("~/.elita/sessions") |> ls() |> merged(agent)
  rescue
    _ -> ""
  end

  defp merged({:ok, files}, agent) do
    dir = expand("~/.elita/sessions")
    file = files |> filter(&starts_with?(&1, "#{agent}_")) |> latest(dir)
    pid = parse(file)
    gather(dir, files, pid)
  end

  defp merged({:error, _}, _agent), do: ""

  defp parse(nil), do: nil

  defp parse(file) do
    file
    |> replace(".log", "")
    |> split("_")
    |> at(-1)
  end

  defp gather(_, _, nil), do: ""
  defp gather(dir, files, pid), do: files |> filter(&match(pid, &1)) |> sort() |> map(&load(&1, dir)) |> concat()

  defp concat(logs), do: reduce(logs, "", fn log, acc -> acc <> log end)

  defp match(pid, file), do: ends_with?(file, "_#{pid}.log")

  defp latest(files, dir) do
    files |> sort_by(&time(dir, &1)) |> last()
  end

  defp time(dir, file) do
    join(dir, file) |> stat!() |> Map.get(:mtime)
  end

  defp load(file, dir) do
    join(dir, file) |> read!()
  end
end
