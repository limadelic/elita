defmodule Cfgs do
  import Enum, only: [map: 2, reject: 2, flat_map: 2, uniq: 1]
  import List, only: [flatten: 1]
  import Map, only: [get: 3]
  import Cfg, only: [config: 1, config: 2]

  def load(names) when is_list(names) do
    names
    |> expand()
    |> map(&config/1)
  end

  def load(name), do: config(name)

  def load(names, cwd) when is_list(names) do
    names
    |> expand(cwd)
    |> map(&config(&1, cwd))
  end

  def load(name, cwd), do: config(name, cwd)

  def value(key, configs) do
    configs
    |> flat_map(&get(&1, key, []))
    |> uniq()
  end

  defp expand(list, cwd \\ nil)

  defp expand(list, nil) do
    gather(list) |> fold(list, nil)
  end

  defp expand(list, cwd) do
    gather(list, cwd) |> fold(list, cwd)
  end

  defp gather(list) do
    list
    |> map(&deps/1)
    |> flatten()
    |> reject(&(&1 in list))
  end

  defp gather(list, cwd) do
    list
    |> map(&deps(&1, cwd))
    |> flatten()
    |> reject(&(&1 in list))
  end

  defp fold([], list, _cwd), do: list
  defp fold(newdeps, list, nil), do: expand(list ++ newdeps)
  defp fold(newdeps, list, cwd), do: expand(list ++ newdeps, cwd)

  defp deps(name) do
    config(name) |> includes()
  end

  defp deps(name, cwd) do
    config(name, cwd) |> includes()
  end

  defp includes(config) do
    get(config, :includes, [])
  end
end
