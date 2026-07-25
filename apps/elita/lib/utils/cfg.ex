defmodule Cfg do
  import Enum, only: [map: 2, reject: 2, reduce: 3]
  import Map, only: [new: 1, put: 3, put_new: 3]
  import String, only: [split: 2, split: 3, trim: 1, to_atom: 1]
  import Utils.File, only: [file: 1]
  import YamlElixir, only: [read_from_string: 1]

  def config(name) do
    file("#{name}.md")
    |> valid(name)
    |> finalize(name)
  end

  defp finalize(md, name), do: md |> parse() |> tools() |> includes() |> default(name: name)

  defp valid("file not found: " <> _, name), do: raise(RuntimeError, "unknown agent: #{name}")
  defp valid(md, _), do: md

  defp tools(%{tools: raw} = config) when is_binary(raw) do
    list = split(raw, ",") |> map(&trim/1) |> reject(&empty/1)
    put(config, :tools, list)
  end

  defp tools(config), do: config

  defp includes(%{includes: raw} = config) when is_binary(raw) do
    list = split(raw, ",") |> map(&trim/1) |> reject(&empty/1)
    put(config, :includes, list)
  end

  defp includes(config), do: config

  defp empty(""), do: true
  defp empty(_), do: false

  defp parse(md) do
    md
    |> split("---", parts: 3)
    |> join(md)
  end

  defp parse(header, body) do
    header
    |> then(&suppress(fn -> read_from_string(&1) end))
    |> join(body)
  end

  defp suppress(fun) do
    fun.()
  end

  defp join(["", header, body], _), do: parse(header, body)
  defp join({:ok, header}, body), do: build(header, body)
  defp join(_, md), do: %{content: md}

  defp build(header, body) do
    header
    |> map(&props/1)
    |> new()
    |> put(:content, trim(body))
  end

  defp props({k, v}), do: {to_atom(k), v}

  defp default(config, defaults) do
    reduce(defaults, config, fn {key, value}, acc ->
      put_new(acc, key, value)
    end)
  end
end
