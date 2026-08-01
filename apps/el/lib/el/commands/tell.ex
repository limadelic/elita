defmodule El.Commands.Tell do
  @moduledoc false
  import Application, only: [get_env: 2]
  import El.Distribution, only: [start: 0, start: 1]
  import System, only: [halt: 1]
  import Node, only: [self: 0]
  import Kernel, except: [self: 0]
  import Keyword, only: [get: 3]
  import IO, only: [write: 2]
  import Registry, only: [lookup: 2]
  import String, only: [downcase: 1]
  import El.Puppet, only: [put: 2]

  def send(agent, msg, _tool \\ nil, _opts \\ []) do
    prime()
    start()
    normalized = agent |> to_string() |> downcase()
    case find_puppet(normalized) do
      nil -> write(:stderr, "unknown: #{agent}\n")
      pid -> put(pid, msg)
    end
  end

  defp find_puppet(normalized) do
    lookup(ElitaRegistry, normalized)
    |> extract_puppet()
  rescue
    _ -> nil
  end

  defp extract_puppet([{pid, %{kind: :puppet}}]), do: pid
  defp extract_puppet(_), do: nil

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
