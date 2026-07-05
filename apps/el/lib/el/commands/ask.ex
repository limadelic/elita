defmodule El.Commands.Ask do
  import Elita, only: [start_link: 2]
  import String, only: [to_atom: 1]
  import IO, only: [puts: 1]
  import Agent.Router, only: [route: 3]

  def execute(agent, msg) do
    {:ok, _pid} = start_link(agent, [agent])
    route(to_atom(agent), :ask, msg) |> output |> puts()
  end

  defp output({:ok, resp}), do: resp
  defp output({:error, :not_found}), do: "not found"
  defp output(resp), do: resp
end
