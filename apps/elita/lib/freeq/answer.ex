defmodule Elita.Freeq.Answer do
  import String, only: [contains?: 2]
  import Elita.Freeq.Parser, only: [parse: 3]
  import Task, only: [start: 1]

  def privmsg(msg, state, pid) do
    privmsg(contains?(msg, "PRIVMSG"), msg, state, pid)
  end

  def privmsg(true, msg, %{agent: agent, channel: channel, ask: ask, driver: driver}, pid) do
    parse(msg, agent, channel) |> reply(agent, ask, pid, driver)
  end

  def privmsg(false, _msg, _state, _pid) do
    :noop
  end

  def reply({:ask, sender, text}, agent, ask, pid, driver) when sender != agent do
    start(fn ->
      ask.(agent, format(sender, text, driver)) |> relay(pid)
    end)
  end

  def reply({:ask, _sender, _text}, _agent, _ask, _pid, _driver), do: :ok

  def reply(:noop, _agent, _ask, _pid, _driver), do: :ok

  defp format(driver, text, driver), do: text
  defp format(sender, text, _driver), do: "[from #{sender}] #{text}"

  def relay({:error, _}, _pid), do: :noop
  def relay(answer, pid), do: send(pid, {:answer, answer})
end
