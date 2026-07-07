defmodule Resolver do
  def resolve(address, world, cwd) do
    {name, path, fanout} = parse(address)
    absolute_path = normalize_path(path, cwd)

    matches = world
      |> filter_by_path(absolute_path)
      |> filter_by_name(name, fanout)

    case apply_precedence(matches) do
      [] -> {:error, :unknown}
      [entry] -> {:ok, entry}
      entries -> {:many, entries}
    end
  end

  defp parse(address) do
    case String.split(address, "@", parts: 2) do
      [name] -> {name, nil, false}
      ["", path] -> {nil, path, true}
      [name, path] -> {name, path, false}
    end
  end

  defp normalize_path(nil, _cwd), do: nil
  defp normalize_path(path, cwd) do
    if String.starts_with?(path, "/") do
      path
    else
      cwd
      |> Path.join(path)
      |> Path.expand()
    end
  end

  defp filter_by_path(world, search_path) do
    world
    |> Enum.filter(&matches_path(&1, search_path))
  end

  defp matches_path(_entry, nil), do: true
  defp matches_path(%{path: entry_path}, search_path) do
    path_matches(entry_path, search_path)
  end

  defp path_matches(entry_path, search_path) do
    cond do
      entry_path == search_path -> true
      contains_glob?(search_path) -> glob_match(entry_path, search_path)
      true -> false
    end
end

  defp contains_glob?(path) do
    String.contains?(path, ["*", "**"])
  end

  defp glob_match(entry_path, pattern) do
    entry_parts = Path.split(entry_path)
    pattern_parts = Path.split(pattern)
    match_parts(entry_parts, pattern_parts)
  end

  defp match_parts(_, []), do: true
  defp match_parts([], _), do: false

  defp match_parts([_entry_h | entry_t], ["**" | pattern_t]) do
    match_parts(entry_t, pattern_t) ||
    match_parts(entry_t, ["**" | pattern_t])
  end

  defp match_parts([_entry_h | entry_t], ["*" | pattern_t]) do
    match_parts(entry_t, pattern_t)
  end

  defp match_parts([entry_h | entry_t], [pattern_h | pattern_t]) do
    if entry_h == pattern_h do
      match_parts(entry_t, pattern_t)
    else
      false
    end
  end

  defp filter_by_name(entries, nil, _fanout) do
    entries
  end

  defp filter_by_name(entries, name, false) do
    Enum.filter(entries, &(&1.name == name))
  end

  defp filter_by_name(entries, _name, true) do
    entries
  end

  defp apply_precedence(entries) do
    entries
    |> Enum.group_by(&{&1.name, &1.path})
    |> Enum.flat_map(&precedence_rule/1)
  end

  defp precedence_rule({_key, [single]}), do: [single]
  defp precedence_rule({_key, multiple}) do
    files = Enum.filter(multiple, &(&1.kind == :file))
    if Enum.empty?(files), do: multiple, else: files
  end
end
