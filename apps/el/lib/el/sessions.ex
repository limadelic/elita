defmodule El.Sessions do
  import File, only: [ls: 1, read!: 1, stat!: 1]
  import Path, only: [expand: 1, join: 2]
  import String, only: [starts_with?: 2]
  import Enum, only: [filter: 2, sort_by: 2]
  import List, only: [last: 1]

  def log(""), do: ""

  def log(agent) do
    expand("~/.elita/sessions") |> ls() |> open(agent)
  rescue
    _ -> ""
  end

  defp open({:ok, f}, agent) do
    dir = expand("~/.elita/sessions")
    f |> filter(&starts_with?(&1, "#{agent}_")) |> latest(dir) |> load(agent)
  end

  defp open({:error, _}, _agent), do: ""

  defp latest(files, dir) do
    files |> sort_by(&mtime(dir, &1)) |> last()
  end

  defp mtime(dir, file) do
    dir |> join(file) |> stat!() |> Map.get(:mtime)
  end

  defp load(nil, _agent), do: ""

  defp load(file, _agent) do
    expand("~/.elita/sessions") |> join(file) |> read!()
  end
end
