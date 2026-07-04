defmodule El.Commands.Ask do
  import Elita, only: [start_link: 2]

  def execute(agent, msg) do
    {:ok, _pid} = start_link(agent, [agent])
    result = Agent.Router.route(String.to_atom(agent), :ask, msg)

    output =
      case result do
        {:ok, resp} -> resp
        {:error, :not_found} -> "#{agent} not found"
        resp -> resp
      end

    IO.puts(output)
  end
end
