defmodule El.Sessions do
  import File, only: [ls: 1, read!: 1, stat!: 1]
  import Path, only: [expand: 1, join: 2]

  import String,
    only: [trim_trailing: 2, split: 2, ends_with?: 2, starts_with?: 2]

  import List, only: [last: 1]

  import Enum,
    only: [
      filter: 2,
      sort_by: 2,
      map_join: 3,
      group_by: 2,
      max_by: 2,
      flat_map: 2,
      map: 2
    ]

  def log(""), do: ""

  def log(agent) do
    expand("~/.elita/sessions") |> ls() |> open(agent)
  rescue
    _ -> ""
  end

  defp open({:ok, all}, agent) do
    dir = expand("~/.elita/sessions")
    latest = rank(all, agent, dir) |> last()
    wrap(latest, all, dir)
  end

  defp open({:error, _}, _agent), do: ""

  defp wrap({f, _t}, all, dir) do
    logs(all, id(f), dir)
  end

  defp wrap(nil, _all, _dir) do
    ""
  end

  defp rank(all, agent, dir) do
    journal(all) |> filter(&starts_with?(&1, "#{agent}_")) |> time(dir)
  end

  defp logs(all, pid, dir) do
    journal(all) |> filter(&(id(&1) == pid)) |> merge(dir)
  end

  defp journal(files), do: filter(files, &ends_with?(&1, ".log"))

  defp time(files, dir) do
    files |> tag(dir) |> sort_by(fn {_f, t} -> t end)
  end

  defp merge(files, dir) do
    files |> tag(dir) |> settle() |> map_join("", &fetch(dir, &1))
  end

  defp settle(annotated) do
    annotated |> group_by(&gather/1) |> sort_by(&peak/1) |> flat_map(&order/1)
  end

  defp gather({f, _}), do: id(f)

  defp tag(files, dir) do
    files |> map(fn f -> {f, mtime(dir, f)} end)
  end

  defp id(file) do
    file |> trim_trailing(".log") |> split("_") |> last()
  end

  defp peak({_pid, items}) do
    items |> max_by(fn {_f, t} -> t end) |> elem(1)
  end

  defp order({_pid, items}) do
    items |> sort_by(fn {f, t} -> {t, f} end) |> map(fn {f, _} -> f end)
  end

  defp mtime(dir, file) do
    dir |> join(file) |> stat!() |> Map.get(:mtime)
  rescue
    _ -> 0
  end

  defp fetch(dir, file) do
    dir |> join(file) |> read!()
  rescue
    _ -> ""
  end
end
