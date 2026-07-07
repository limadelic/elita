defmodule El.Commands.Ls do
  @moduledoc "Lists agents in the current folder with their registration status."

  import IO, only: [puts: 1]
  import Enum, only: [map: 2, sort_by: 2, filter: 2, join: 2]
  import El.Commands.Address.World, only: [build: 0, cwd: 0]

  def execute(opts \\ []) do
    path = Keyword.get(opts, :path, nil)
    render(path) |> puts()
  end

  def remote(opts \\ []) do
    path = Keyword.get(opts, :path, nil)
    render(path)
  end

  defp render(path) do
    world = build()
    here = cwd()
    target = resolve_path(path, here)
    world |> filter_path(target) |> sort_by(& &1.name) |> format_output()
  end

  defp resolve_path(nil, _cwd), do: nil
  defp resolve_path("/" <> _ = path, _cwd), do: path
  defp resolve_path(path, cwd), do: cwd |> Path.join(path) |> Path.expand()

  defp filter_path(world, nil), do: world
  defp filter_path(world, target) do
    world |> filter(&matches_path?(&1, target))
  end

  defp matches_path?(%{path: p}, t) when p == t, do: true
  defp matches_path?(%{path: p}, t), do: glob_match(p, t)
  defp matches_path?(_, _), do: false

  defp glob_match(entry_path, pattern) do
    skip_glob(has_glob?(pattern), entry_path, pattern)
  end

  defp skip_glob(false, _entry_path, _pattern), do: false
  defp skip_glob(true, entry_path, pattern), do: glob(entry_path, pattern)

  defp has_glob?(pattern) do
    String.contains?(pattern, ["*", "**"])
  end

  defp glob(entry_path, pattern) do
    match(String.split(entry_path, "/"), String.split(pattern, "/"))
  end

  defp match(_, []), do: true
  defp match([], ["**" | t]), do: match([], t)
  defp match([], _), do: false
  defp match(e, ["**" | t]), do: check_double(match(e, t), e, t)
  defp match([_ | et], ["*" | pt]), do: match(et, pt)
  defp match([eh | et], [eh | pt]), do: match(et, pt)
  defp match([_ | _], [_ | _]), do: false

  defp check_double(true, _e, _t), do: true
  defp check_double(false, [_ | et], t), do: match(et, ["**" | t])
  defp check_double(false, [], _t), do: false

  defp format_output([]) do
    "no agents"
  end

  defp format_output(entries) do
    entries |> map(&format/1) |> join("\n")
  end

  defp format(entry) do
    "#{entry.name} #{kind_label(entry.kind)} #{status(entry.name)}"
  end

  defp status(name) do
    normalized = String.downcase(to_string(name))
    Registry.lookup(ElitaRegistry, normalized) |> map_status()
  end

  defp map_status([_ | _]), do: "active"
  defp map_status([]), do: "asleep"

  defp kind_label(:file), do: "file"
  defp kind_label(:folder), do: "folder"
end
