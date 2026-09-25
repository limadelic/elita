defmodule El.Commands.Nodes do
  import El.Commands.Address.World, only: [build: 0]
  import Enum, only: [filter: 2, sort_by: 2, map: 2, join: 2]

  def list do
    build()
    |> filter(&(&1.kind == :node))
    |> sort_by(& &1.name)
    |> show()
  end

  defp show([]) do
    "no agents"
  end

  defp show(entries) do
    entries |> map(&format/1) |> join("\n")
  end

  defp format(%{kind: :node} = entry) do
    "#{entry.name} #{label(entry.kind)}"
  end

  defp label(:node), do: "node"
end
