defmodule El.Commands.Nodes do
  import El.Commands.Address.World, only: [build: 0]
  import Enum, only: [filter: 2, sort_by: 2]

  def list do
    build()
    |> filter(&(&1.kind == :node))
    |> sort_by(& &1.name)
  end
end
