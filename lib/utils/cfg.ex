defmodule Cfg do
  import String, only: [split: 3, trim: 1, to_atom: 1]
  import Enum, only: [map: 2, reduce: 3]
  import Map, only: [new: 1, put: 3]
  import YamlElixir, only: [read_from_string: 1]

  def config(names) when is_list(names) do
    names
    |> map(&load/1)
    |> compose
  end

  def config(name), do: config([name])

  defp load(name) do
    {:ok, md} = File.read("agents/#{name}.md")
    parse md
  end

  defp compose(configs) do
    configs
    |> headers
    |> content(configs)
  end

  defp headers(configs) do
    configs
    |> map(&drop/1)
    |> reduce(%{}, &Map.merge/2)
  end

  defp content(merged, configs) do
    text = configs |> map(&extract/1) |> Enum.join("\n\n")
    put(merged, :content, text)
  end

  defp drop(config), do: Map.drop(config, [:content])
  defp extract(config), do: Map.get(config, :content, "")

  defp parse md do
    md
    |> split("---", parts: 3)
    |> join(md)
  end

  defp parse header, body do
    header
    |> then(&suppress(fn -> read_from_string(&1) end))
    |> join(body)
  end

  defp suppress(fun) do
    fun.()
  end

  defp join(["", header, body], _), do: parse(header, body)
  defp join({:ok, header}, body), do: to_map(header, body)
  defp join(_, md), do: %{content: md}

  defp to_map header, body do
    header
    |> map(&props/1)
    |> new
    |> put(:content, trim(body))
  end

  defp props({k, v}), do: {to_atom(k), v}
end
