defmodule Cfgs do
  import Enum, only: [map: 2, reject: 2, flat_map: 2, uniq: 1]
  import List, only: [flatten: 1]
  import Map, only: [get: 3]
  import Cfg, only: [config: 1]

  def load(names) when is_list(names) do
    names
    |> expand()
    |> map(&config/1)
  end

  def load(name), do: config(name)

  def value(key, configs) do
    configs
    |> flat_map(&get(&1, key, []))
    |> uniq()
  end

  defp expand(list) do
    deps = gather(list)
    expand(list, deps)
  end

  defp gather(list) do
    list
    |> map(&deps/1)
    |> flatten()
    |> reject(&(&1 in list))
  end

  defp expand(list, []), do: list
  defp expand(list, deps), do: expand(list ++ deps)

  defp deps(name) do
    config(name) |> includes()
  end

  defp includes(config) do
    get(config, :includes, [])
  end
end
