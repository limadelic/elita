defmodule El.Commands.Ask do
  import Elita, only: [start_link: 2]
  import String, only: [to_atom: 1]
  import IO, only: [puts: 1]

  def execute(agent, msg) do
    {:ok, _pid} = start_link(agent, [agent])
    result = Agent.Router.route(to_atom(agent), :ask, msg)

    output =
      case result do
        {:ok, resp} -> resp
        {:error, :not_found} -> "#{agent} not found"
        resp -> resp
      end

    puts(output)
  end
end
