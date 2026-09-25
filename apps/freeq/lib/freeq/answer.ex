defmodule Freeq.Answer do
  import String, only: [contains?: 2]
  import Freeq.Parser, only: [parse: 3]
  import Task, only: [start: 1]
  import Kernel, except: [spawn: 3]
  import Elita, only: [spawn: 3]

  def privmsg(msg, state, pid) do
    privmsg(contains?(msg, "PRIVMSG"), msg, state, pid)
  end

  def privmsg(true, msg, %{agent: agent, channel: channel, ask: ask, config: c}, pid) do
    parse(msg, agent, channel) |> reply(agent, ask, pid, c)
  end

  def privmsg(false, _msg, _state, _pid) do
    :noop
  end

  def reply({:ask, s, t}, a, k, p, c) do
    reply(%{sender: s, text: t, agent: a, ask: k, pid: p, config: c})
  end

  def reply(:noop, _agent, _ask, _pid, _c), do: :ok

  defp reply(ctx), do: handle(kind(ctx), ctx)

  defp kind(%{sender: s, agent: a}) when s == a, do: :same
  defp kind(_), do: :other

  defp handle(:same, _), do: :ok

  defp handle(:other, %{sender: s, text: t, agent: a, ask: ask, pid: p, config: c}) do
    start(fn -> safe(ask, a, s, t, c) |> relay(p, s) end)
  end

  defp safe(ask, agent, sender, text, config) do
    ask.(agent, "[from #{sender}] #{text}")
  catch
    _, _ -> live(agent, config)
  end

  defp live(agent, config) do
    spawn(agent, [agent], config)
    {:error, :failed}
  end

  def relay({:error, _}, pid, sender), do: send(pid, {:error_answer, sender})
  def relay(answer, pid, sender), do: send(pid, {:answer, answer, sender})
end
