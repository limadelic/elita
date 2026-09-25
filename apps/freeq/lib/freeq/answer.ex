defmodule Freeq.Answer do
  import String, only: [contains?: 2]
  import Freeq.Parser, only: [parse: 3]
  import Task, only: [start: 1]
  import Kernel, except: [spawn: 3]
  import Elita, only: [spawn: 3]

  def privmsg(msg, state, pid) do
    privmsg(contains?(msg, "PRIVMSG"), msg, state, pid)
  end

  def privmsg(true, msg, %{agent: agent, channel: channel, ask: ask, config: config}, pid) do
    parse(msg, agent, channel) |> reply(agent, ask, pid, config)
  end

  def privmsg(false, _msg, _state, _pid) do
    :noop
  end

  def reply({:ask, sender, text}, agent, ask, pid, config) do
    reply(%{
      sender: sender, text: text, agent: agent,
      ask: ask, pid: pid, config: config
    })
  end

  def reply(:noop, _agent, _ask, _pid, _config), do: :ok

  defp reply(ctx), do: handle(kind(ctx), ctx)

  defp kind(%{sender: sender, agent: agent}) when sender == agent, do: :same
  defp kind(_), do: :other

  defp handle(:same, _), do: :ok

  defp handle(:other, context) do
    start(fn -> task(context) end)
  end

  defp task(context) do
    %{ask: ask, agent: agent, sender: sender, text: text,
      config: config, pid: pid} = context
    safe(ask, agent, sender, text, config) |> relay(pid, sender)
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
