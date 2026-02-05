defmodule Compose do
  import Enum, only: [map: 2, reduce: 3, reject: 2, uniq: 1, join: 2]
  import Map, only: [put: 3, merge: 2, drop: 2, get: 3]

  def compose([main | rest]) do
    active = [main | reject(rest, & &1[:active] == false)]
    active |> headers |> content(active)
  end

  defp headers(configs) do
    configs
    |> map(&strip/1)
    |> reduce(%{}, &combine/2)
  end

  defp combine(config, acc) do
    tools = (acc[:tools] || []) ++ (config[:tools] || []) |> uniq
    merge(acc, config) |> put(:tools, tools)
  end

  defp content(merged, configs) do
    text = configs |> map(&extract/1) |> join("\n\n")
    put(merged, :content, text)
  end

  defp strip(config), do: drop(config, [:content])
  defp extract(config), do: get(config, :content, "")
end
