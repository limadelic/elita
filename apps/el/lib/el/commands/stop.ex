defmodule El.Commands.Stop do
  @moduledoc false
  import El.Distribution, only: [start: 0]
  import El.Commands.Tell, only: [target: 2]
  import IO, only: [puts: 1]
  import Keyword, only: [get: 3]
  import Node, only: [monitor: 2]

  def stop(agent, opts \\ []) do
    start()
    env = get(opts, :env_module, El.Infra.Env)
    node = target(agent, env_module: env)
    halt(node, agent)
  end

  defp halt(nil, agent) do
    puts("session #{agent} not found")
  end

  defp halt(node, agent) do
    :ok = monitor(node, true)
    signal(node, agent)
  end

  defp signal(node, agent) do
    :rpc.call(node, :init, :stop, [0]) |> handle(node, agent)
  end

  defp handle(:ok, node, agent), do: wait(node, agent)
  defp handle(_, _node, agent), do: puts("stop failed: #{agent}")

  defp wait(node, agent) do
    receive do
      {:nodedown, ^node} -> puts("stopped: #{agent}")
    after
      5000 -> puts("stop timeout: #{agent}")
    end
  end
end
