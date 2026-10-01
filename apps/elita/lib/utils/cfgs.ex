defmodule Cfgs do
  import Enum, only: [map: 2, reject: 2, flat_map: 2, uniq: 1]
  import List, only: [flatten: 1]
  import Map, only: [get: 3]
  import Cfg, only: [config: 2]

  def load(names, cwd \\ nil)
  def load(names, cwd) when is_list(names), do: names |> expand(cwd) |> map(&config(&1, cwd))
  def load(name, cwd), do: config(name, cwd)

  def value(key, configs) do
    configs
    |> flat_map(&get(&1, key, []))
    |> uniq()
  end

  defp expand(list, cwd), do: expand(list, gather(list, cwd), cwd)
  defp expand(list, [], _cwd), do: list
  defp expand(list, deps, cwd), do: expand(list ++ deps, cwd)

  defp gather(list, cwd) do
    list
    |> map(&deps(&1, cwd))
    |> flatten()
    |> reject(&(&1 in list))
  end

  defp deps(name, cwd) do
    config(name, cwd) |> includes()
  end

  defp includes(config) do
    get(config, :includes, [])
  end
end
