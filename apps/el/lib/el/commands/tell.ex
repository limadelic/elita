defmodule El.Commands.Tell do
  import Elita, only: [start_link: 2, cast: 2]

  def execute(agent, msg) do
    {:ok, _pid} = start_link(agent, [agent])
    cast(agent, msg)
  end
end
