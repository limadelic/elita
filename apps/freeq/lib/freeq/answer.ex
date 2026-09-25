defmodule Freeq.Answer do
  import String, only: [contains?: 2]
  import Freeq.Parser, only: [parse: 3]
  import Task, only: [start: 1]
  import Elita, only: [dispatch: 2]

  def privmsg(msg, state, pid) do
    privmsg(contains?(msg, "PRIVMSG"), msg, state, pid)
  end

  def privmsg(true, msg, %{agent: agent, channel: channel, ask: ask, driver: driver}, pid) do
    parse(msg, agent, channel) |> reply(agent, ask, pid, driver)
  end

  def privmsg(false, _msg, _state, _pid) do
    :noop
  end

  def reply({:ask, s, t}, a, k, p, d) do
    reply(%{sender: s, text: t, agent: a, ask: k, pid: p, driver: d})
  end

  def reply(:noop, _agent, _ask, _pid, _driver), do: :ok

  defp reply(ctx), do: handle(kind(ctx), ctx)

  defp kind(%{sender: s, agent: a}) when s == a, do: :same
  defp kind(%{sender: s, driver: d}) when s == d, do: :driver
  defp kind(_), do: :other

  defp handle(:same, _), do: :ok

  defp handle(:driver, %{sender: s, text: t, agent: a, ask: ask, pid: p, driver: d}) do
    start(fn -> ask.(a, format(s, t, d)) |> relay(p) end)
  end

  defp handle(:other, %{sender: s, text: t, agent: a, driver: d}) do
    dispatch(a, format(s, t, d))
  end

  defp format(driver, text, driver), do: text
  defp format(sender, text, _driver), do: "[from #{sender}] #{text}"

  def relay({:error, _}, _pid), do: :noop
  def relay(answer, pid), do: send(pid, {:answer, answer})
end
