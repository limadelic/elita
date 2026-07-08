defmodule Cfgs do
  import Enum, only: [map: 2, reject: 2, flat_map: 2, uniq: 1]
  import List, only: [flatten: 1]
  import Map, only: [get: 3]
  import Cfg
  import Atom

  def config(names) when is_list(names) do
    names
    |> expand()
    |> map(&Cfg.config/1)
  end

  def config(name), do: Cfg.config(name)

  def value(key, configs) do
    configs
    |> flat_map(&get(&1, key, []))
    |> uniq()
  end

  defp expand(list) do
    deps = gather_deps(list)
    expand(list, deps)
  end

  defp gather_deps(list) do
    list
    |> map(&deps/1)
    |> flatten()
    |> reject(&(&1 in list))
  end

  defp expand(list, []), do: list
  defp expand(list, deps), do: expand(list ++ deps)

  defp deps(name) do
    Cfg.config(name) |> includes()
  end

  defp includes(config) do
    get(config, :includes, [])
  end
end
