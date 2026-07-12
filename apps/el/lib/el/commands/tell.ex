defmodule El.Commands.Tell do
  @moduledoc false
  import El.Distribution, only: [start: 0]
  import System, only: [get_env: 2, halt: 1]
  import Node, only: [start: 2, set_cookie: 1]
  import Keyword, only: [get: 3]
  import IO, only: [write: 2]

  def tell(agent, msg, _tool \\ nil, _opts \\ []) do
    prime()
    start()
    sender = get_env("EL_FROM", node() |> to_string())
    El.Wrap.Remote.tell(agent, msg, sender) |> code()
  end

  defp code(:forward), do: halt(1)
  defp code(_), do: :ok

  def target(agent, opts \\ []) do
    env = get(opts, :env_module, El.Infra.Env)
    node(agent, env.get("EL_NODE"))
  end

  defp node(_agent, nil), do: nil
  defp node(agent, host), do: :"claude_#{agent}@#{host}"

  def unreachable(agent, host) do
    write(:stderr, "session #{agent} unreachable at #{host}\n")
  end

  defp prime do
    case Node.self() do
      :nonode@nohost -> start(:"tell_#{:erlang.system_time(:millisecond)}@127.0.0.1", :longnames); set_cookie(:elita)
      _ -> set_cookie(:elita)
    end
  end
end
