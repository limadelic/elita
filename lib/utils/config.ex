defmodule AgentConfig do
  import String, only: [split: 3, trim: 1, to_atom: 1]
  import Enum, only: [map: 2]
  import Map, only: [new: 1, put: 3]
  import YamlElixir, only: [read_from_string: 1]

  def config name do
    {:ok, md} = File.read "agents/#{name}.md"
    parse md
  end

  defp parse md do
    md
    |> split("---", parts: 3)
    |> join(md)
  end

  defp parse header, body do
    header
    |> read_from_string
    |> join(body)
  end

  defp join(["", header, body], _), do: parse(header, body)
  defp join({:ok, header}, body), do: to_map(header, body)
  defp join(_, md), do: %{content: md}

  defp to_map header, body do
    header
    |> map(&props/1)
    |> new
    |> put(:content, trim body)
  end

  defp props({k, v}), do: {to_atom(k), v}
end
