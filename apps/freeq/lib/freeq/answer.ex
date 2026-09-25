defmodule Freeq.Answer do
  import String, only: [contains?: 2]
  import Freeq.Parser, only: [parse: 3]
  import Task, only: [start: 1]

  def privmsg(msg, state, pid) do
    privmsg(contains?(msg, "PRIVMSG"), msg, state, pid)
  end

  def privmsg(true, msg, %{agent: agent, channel: channel, ask: ask}, pid) do
    parse(msg, agent, channel) |> reply(agent, ask, pid)
  end

  def privmsg(false, _msg, _state, _pid) do
    :noop
  end

  def reply({:ask, s, t}, a, k, p) do
    reply(%{sender: s, text: t, agent: a, ask: k, pid: p})
  end

  def reply(:noop, _agent, _ask, _pid), do: :ok

  defp reply(ctx), do: handle(kind(ctx), ctx)

  defp kind(%{sender: s, agent: a}) when s == a, do: :same
  defp kind(_), do: :other

  defp handle(:same, _), do: :ok

  defp handle(:other, %{sender: s, text: t, agent: a, ask: ask, pid: p}) do
    start(fn -> ask.(a, "[from #{s}] #{t}") |> relay(p, s) end)
  end

  def relay({:error, _}, _pid, _sender), do: :noop
  def relay(answer, pid, sender), do: send(pid, {:answer, answer, sender})
end
