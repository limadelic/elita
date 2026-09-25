defmodule El.Commands.Stop do
  @moduledoc false
  import El.Distribution, only: [start: 0]
  import El.Commands.Tell, only: [target: 2]
  import IO, only: [puts: 1]
  import Keyword, only: [get: 3]
  import Utils.Normalize, only: [name: 1]

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
    signal(node, agent, name(agent))
  end

  defp signal(node, agent, normalized) do
    fetch(node, normalized) |> term(node, agent)
  end

  defp fetch(node, normalized) do
    :erpc.call(node, Registry, :lookup, [ElitaRegistry, normalized], 5_000)
  catch
    _, _ -> []
  end

  defp term([{pid, _} | _], node, agent) do
    :erpc.call(node, DynamicSupervisor, :terminate_child, [Elita.Spawner, pid], 5_000)
    puts("stopped: #{agent}")
  end

  defp term([], _node, agent) do
    puts("stop failed: #{agent}")
  end
end
