defmodule Agent.Portal do
  import Agent.Session, only: [ask: 2]

  def response(agent, question) do
    locate() |> handle(agent, question)
  end

  defp locate do
    Process.whereis(:puppet)
  end

  defp handle(nil, agent, _question) do
    "unknown: #{agent}"
  end

  defp handle(pid, _agent, question) do
    {:ok, resp} = ask(pid, question)
    resp
  end
end
