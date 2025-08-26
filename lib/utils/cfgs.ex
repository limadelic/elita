defmodule Cfgs do
  import Enum, only: [map: 2, reject: 2, flat_map: 2, uniq: 1]
  import Map, only: [get: 3]

  def config(names) when is_list(names) do
    names
    |> expand
    |> map(&Cfg.config/1)
  end

  def config(name), do: Cfg.config(name)

  def value(key, configs) do
    configs
    |> flat_map(&get(&1, key, []))
    |> uniq()
  end

  defp expand(list) do
    deps =
      list
      |> map(&deps/1)
      |> List.flatten()
      |> reject(&(&1 in list))

    expand(list, deps)
  end

  defp expand(list, []), do: list
  defp expand(list, deps), do: expand(list ++ deps)

  defp deps(name) do
    config = Cfg.config(name)
    config[:includes] || []
  end
end
