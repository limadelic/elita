defmodule Resolver do
  @moduledoc """
  Pure address resolver for agent discovery.

  Matches addresses against a tree snapshot with support for
  bare names, paths, globs, and fanout patterns.
  """

  import Enum, only: [filter: 2, group_by: 2, flat_map: 2]
  import Path, only: [join: 2, expand: 1]
  import String, only: [split: 3]
  import Glob, only: [wild?: 1]

  def resolve(address, world, cwd) do
    world
    |> filter(&(&1.kind == :node))
    |> filter(&(&1.name == address))
    |> maybe_node(address, world, cwd)
  end

  defp maybe_node([entry], _address, _world, _cwd), do: {:ok, entry}

  defp maybe_node([], address, world, cwd) do
    {name, path, fanout} = unpack(address)
    world |> path(normalize(path, cwd)) |> named(name, fanout) |> rank()
  end

  defp maybe_node(entries, _address, _world, _cwd), do: {:many, entries}

  defp unpack([name]), do: {name, nil, false}
  defp unpack(["", path]), do: {nil, path, true}
  defp unpack([name, path]), do: {name, path, false}

  defp unpack(address) do
    address |> split("@", parts: 2) |> unpack()
  end

  def normalize(nil, _cwd), do: nil
  def normalize("/" <> _ = path, _cwd), do: path
  def normalize(path, cwd), do: cwd |> join(path) |> expand()

  defp path(world, search_path),
    do: filter(world, &matches_path?(&1, search_path))

  defp matches_path?(_entry, nil), do: true
  defp matches_path?(%{path: p}, s), do: path_match(p, s)

  defp path_match(p, p), do: true
  defp path_match(p, s), do: glob_or_fail(wild?(s), p, s)

  defp glob_or_fail(true, p, s), do: Glob.match?(p, s)
  defp glob_or_fail(false, _p, _s), do: false

  defp named(entries, nil, _fanout), do: entries
  defp named(entries, name, false), do: filter(entries, &(&1.name == name))
  defp named(entries, _name, true), do: entries

  defp rank([]), do: {:error, :unknown}
  defp rank([entry]), do: {:ok, entry}

  defp rank(entries) do
    entries
    |> group_by(&{&1.name, &1.path})
    |> flat_map(&prefer/1)
    |> rank_result()
  end

  defp prefer({_key, [single]}), do: [single]
  defp prefer({_key, multiple}), do: prefer_files(multiple)

  defp prefer_files(entries) do
    files = filter(entries, &(&1.kind == :file))
    pick_files(files, entries)
  end

  defp pick_files([_ | _] = files, _entries), do: files
  defp pick_files([], entries), do: entries

  defp rank_result([entry]), do: {:ok, entry}
  defp rank_result(entries), do: {:many, entries}
end
