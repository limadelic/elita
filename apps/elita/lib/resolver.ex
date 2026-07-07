defmodule Resolver do
  @moduledoc """
  Pure address resolver for agent discovery.

  Matches addresses against a tree snapshot with support for
  bare names, paths, globs, and fanout patterns.
  """

  import String, only: [split: 3, contains?: 2]
  import Path, only: [join: 2, expand: 1, split: 1]
  import Enum, only: [filter: 2, group_by: 2, flat_map: 2, empty?: 1]

  def resolve(address, world, cwd) do
    {name, path, fanout} = parse(address)
    absolute_path = normalize(path, cwd)

    matches =
      world
      |> path(absolute_path)
      |> named(name, fanout)

    case precedence(matches) do
      [] -> {:error, :unknown}
      [entry] -> {:ok, entry}
      entries -> {:many, entries}
    end
  end

  defp parse(address) do
    case split(address, "@", parts: 2) do
      [name] -> {name, nil, false}
      ["", path] -> {nil, path, true}
      [name, path] -> {name, path, false}
    end
  end

  defp normalize(nil, _cwd), do: nil
  defp normalize("/" <> _ = path, _cwd), do: path

  defp normalize(path, cwd) do
    cwd
    |> join(path)
    |> expand()
  end

  defp path(world, search_path) do
    filter(world, &match_path(&1, search_path))
  end

  defp match_path(_entry, nil), do: true

  defp match_path(%{path: entry_path}, search_path) do
    if entry_path == search_path do
      true
    else
      if glob?(search_path) do
        glob(entry_path, search_path)
      else
        false
      end
    end
  end

  defp glob?(pattern) do
    contains?(pattern, ["*", "**"])
  end

  defp glob(entry_path, pattern) do
    entry_parts = split(entry_path)
    pattern_parts = split(pattern)
    match(entry_parts, pattern_parts)
  end

  defp match(_, []), do: true
  defp match([], ["**" | pattern_t]), do: match([], pattern_t)
  defp match([], _), do: false

  defp match(entries, ["**" | pattern_t]) do
    match(entries, pattern_t) ||
      case entries do
        [_h | entry_t] -> match(entry_t, ["**" | pattern_t])
        [] -> false
      end
  end

  defp match([_entry_h | entry_t], ["*" | pattern_t]) do
    match(entry_t, pattern_t)
  end

  defp match([entry_h | entry_t], [pattern_h | pattern_t]) do
    if entry_h == pattern_h do
      match(entry_t, pattern_t)
    else
      false
    end
  end

  defp named(entries, nil, _fanout) do
    entries
  end

  defp named(entries, name, false) do
    filter(entries, &(&1.name == name))
  end

  defp named(entries, _name, true) do
    entries
  end

  defp precedence(entries) do
    entries
    |> group_by(&{&1.name, &1.path})
    |> flat_map(&rule/1)
  end

  defp rule({_key, [single]}), do: [single]

  defp rule({_key, multiple}) do
    files = filter(multiple, &(&1.kind == :file))
    if empty?(files), do: multiple, else: files
  end
end
