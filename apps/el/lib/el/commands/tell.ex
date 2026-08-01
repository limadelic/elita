defmodule El.Commands.Tell do
  @moduledoc false
  import El.Distribution, only: [start: 0, start: 1]
  import Node, only: [self: 0]
  import Kernel, except: [self: 0]
  import Keyword, only: [get: 3]
  import IO, only: [write: 2]
  import Registry, only: [lookup: 2]
  import String, only: [downcase: 1]
  import El.Puppet, only: [put: 2]
  import Elita, only: [dispatch: 2]

  def send(agent, msg, _tool \\ nil, _opts \\ []) do
    prime()
    start()
    deliver(agent, msg)
  end

  defp deliver(agent, msg) do
    normalized = agent |> to_string() |> downcase()
    route(locate(normalized), agent, msg)
  end

  defp route(nil, agent, _msg), do: write(:stderr, "unknown: #{agent}\n")
  defp route({:puppet, pid}, _agent, msg), do: put(pid, msg)
  defp route({:native, name}, _agent, msg), do: dispatch(name, msg)

  defp locate(normalized) do
    lookup(ElitaRegistry, normalized)
    |> extract(normalized)
  rescue
    _ -> nil
  end

  defp extract([{pid, %{kind: :puppet}}], _n), do: {:puppet, pid}
  defp extract([{_pid, _meta}], n), do: {:native, n}
  defp extract(_, _n), do: nil

  def target(agent, opts \\ []) do
    env = get(opts, :env_module, El.Infra.Env)
    node(agent, env.get("EL_NODE"))
  end

  defp node(_agent, nil), do: nil
  defp node(agent, host), do: :"claude_#{agent}@#{host}"

  def unreachable(agent, host) do
    write(:stderr, "session #{agent} unreachable at #{host}\n")
  end

  defp prime, do: prime(self())

  defp prime(:nonode@nohost) do
    start("tell_#{:erlang.system_time(:millisecond)}")
  end

  defp prime(_), do: :ok
end
