defmodule El.Commands.Ask do
  import Elita, only: [start_link: 2, call: 2]

  def execute(agent, msg) do
    {:ok, _pid} = start_link(agent, [agent])
    result = call(agent, msg)
    IO.puts(result)
  end
end
