defmodule El.Sessions do
  import File, only: [ls: 1, read!: 1]
  import Path, only: [expand: 1, join: 2]
  import String, only: [starts_with?: 2]
  import Enum, only: [filter: 2, sort: 1]
  import List, only: [last: 1]

  def log(""), do: ""

  def log(agent) do
    expand("~/.elita/sessions") |> ls() |> open(agent)
  rescue
    _ -> ""
  end

  defp open({:ok, f}, agent) do
    f |> filter(&starts_with?(&1, "#{agent}_")) |> sort() |> last() |> load(agent)
  end

  defp open({:error, _}, _agent), do: ""

  defp load(nil, _agent), do: ""

  defp load(file, _agent) do
    expand("~/.elita/sessions") |> join(file) |> read!()
  end
end
