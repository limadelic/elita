defmodule Agent.Portal do
  import Agent.Session, only: [ask: 2]
  import Agent.Watch, only: [start: 2]
  import Log, only: [ask: 3, answer: 2]
  import String, only: [trim: 1]

  def response(agent, question) do
    ask("user", "el.#{agent}", question)
    start(agent, question)
    handle(agent, question)
  end

  defp handle(agent, question) do
    reply = process(locate(), agent, question)
    log(agent, reply)
    reply
  end

  defp process(nil, agent, _) do
    "unknown: #{agent}"
  end

  defp process(pid, _, question) do
    {:ok, resp} = ask(pid, question)
    resp
  end

  defp log(_, reply) when not is_binary(reply), do: :ok
  defp log(_, reply) when byte_size(reply) == 0, do: :ok
  defp log(agent, reply), do: answer(agent, trim(reply))

  defp locate do
    Process.whereis(:puppet)
  end
end
