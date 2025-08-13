defmodule Cfgs do
  import Enum, only: [map: 2, reduce: 3]
  import Map, only: [put: 3]
  def config(names) when is_list(names) do
    names
    |> map(&Cfg.config/1)
    |> compose
  end

  def config(name), do: Cfg.config(name)

  defp compose(configs) do
    configs
    |> headers
    |> content(configs)
  end

  defp headers(configs) do
    configs
    |> map(&drop/1)
    |> reduce(%{}, &combine/2)
  end

  defp combine(config, acc) do
    tools = (acc[:tools] || []) ++ (config[:tools] || [])
    Map.merge(acc, config) |> put(:tools, tools)
  end

  defp content(merged, configs) do
    text = configs |> map(&extract/1) |> Enum.join("\n\n")
    put(merged, :content, text)
  end

  defp drop(config), do: Map.drop(config, [:content])
  defp extract(config), do: Map.get(config, :content, "")
end