defmodule El.Commands.Tell do
  @moduledoc false
  import Elita, only: [start_link: 2, cast: 2]
  alias El.Distribution

  def execute(agent, msg, opts \\ []) do
    Distribution.start()
    env_module = Keyword.get(opts, :env_module, El.Infra.Env)

    case remote_target(agent, env_module: env_module) do
      nil -> default(agent, msg)
      target -> attempt_inject(msg, target, agent, env_module)
    end
  end

  def remote_target(agent, opts \\ []) do
    env_module = Keyword.get(opts, :env_module, El.Infra.Env)

    case env_module.get("EL_NODE") do
      nil -> nil
      host -> :"claude_#{agent}@#{host}"
    end
  end

  defp attempt_inject(msg, target, agent, env_module) do
    process_name = String.to_atom(agent)

    if Node.connect(target) do
      inject(msg, target, process_name)
    else
      host = env_module.get("EL_NODE")
      remote_unreachable(agent, host)
      default(agent, msg)
    end
  end

  def remote_unreachable(agent, host) do
    IO.write(:stderr, "session #{agent} unreachable at #{host}\n")
  end

  defp inject(msg, target, process_name) do
    text = cond do
      String.contains?(msg, "\n") ->
        "\e[200~#{msg}\e[201~\r"
      control_sequence?(msg) ->
        msg
      true ->
        "#{msg}\r"
    end
    GenServer.cast({process_name, target}, {:inject, text})
  end

  defp control_sequence?(msg) do
    case :binary.at(msg, 0) do
      nil -> false
      byte -> byte < 32 or byte == 0x1B
    end
  end

  defp default(agent, msg) do
    {:ok, _pid} = start_link(agent, [agent])
    cast(agent, msg)
  end
end
