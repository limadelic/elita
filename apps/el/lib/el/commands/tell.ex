defmodule El.Commands.Tell do
  import Elita, only: [start_link: 2]
  import String, only: [to_atom: 1]

  def execute(agent, msg) do
    {:ok, _pid} = start_link(agent, [agent])
    Agent.Router.route(to_atom(agent), :tell, msg)
  end
end
