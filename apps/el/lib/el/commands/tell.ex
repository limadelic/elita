defmodule El.Commands.Tell do
  import Elita, only: [start_link: 2]

  def execute(agent, msg) do
    {:ok, _pid} = start_link(agent, [agent])
    Agent.Router.route(String.to_atom(agent), :tell, msg)
  end
end
