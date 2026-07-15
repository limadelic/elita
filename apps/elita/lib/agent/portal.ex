defmodule Agent.Portal do
  import Agent.Session, only: [ask: 2]
  import Agent.Watch, only: [start: 2]
  import String, only: [trim: 1]
  import Process, only: [whereis: 1]

  def response(agent, question) do
    query("user", "el.#{agent}", question)
    start(agent, question)
    handle(agent, question)
  end

  defp handle(agent, question) do
    reply = process(locate(), agent, question)
    respond(agent, reply)
    reply
  end

  defp process(nil, agent, _) do
    "unknown: #{agent}"
  end

  defp process(pid, _, question) do
    {:ok, resp} = ask(pid, question)
    resp
  end

  defp respond(_, reply) when not is_binary(reply), do: :ok
  defp respond(_, reply) when byte_size(reply) == 0, do: :ok
  defp respond(agent, reply), do: answer(agent, trim(reply))

  defp locate do
    whereis(:puppet)
  end

  defp answer(agent, text) do
    :erlang.apply(:"Elixir.Tools.Sys.Ask", :answer, [agent, text])
  rescue
    _ -> :ok
  end

  defp query(role, context, question) do
    :erlang.apply(:"Elixir.Tools.Sys.Ask", :query, [role, context, question])
  rescue
    _ -> :ok
  end
end
