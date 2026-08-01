defmodule El.Commands.Tell do
  @moduledoc false
  import El.Distribution, only: [start: 0]
  import El.Commands.Address, only: [route: 4]
  import El.Commands.Address.Send, only: [tell: 3]
  import String, only: [contains?: 2]
  import Keyword, only: [get: 3]
  import IO, only: [write: 2]

  def send(agent, msg, tool \\ nil, _opts \\ []) do
    start()
    text = agent |> to_string()
    dispatch(agent, msg, tool, contains?(text, "@"))
  end

  defp dispatch(agent, msg, tool, true) do
    route(to_string(agent), msg, :tell, tool)
  end

  defp dispatch(agent, msg, tool, false) do
    tell(to_string(agent), msg, tool)
  end

  def target(agent, opts \\ []) do
    env = get(opts, :env_module, El.Infra.Env)
    node(agent, env.get("EL_NODE"))
  end

  defp node(_agent, nil), do: nil
  defp node(agent, host), do: :"claude_#{agent}@#{host}"

  def unreachable(agent, host) do
    write(:stderr, "session #{agent} unreachable at #{host}\n")
  end
end
