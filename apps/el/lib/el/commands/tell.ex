defmodule El.Commands.Tell do
  @moduledoc false
  import String, only: [contains?: 2]
  import :binary, only: [at: 2]
  import El.Commands.Address, only: [route: 3]
  alias El.Distribution

  def execute(agent, msg, opts \\ []) do
    Distribution.start()
    env_module = Keyword.get(opts, :env_module, El.Infra.Env)
    dispatch(contains?(agent, "@"), agent, msg, env_module)
  end

  defp dispatch(true, agent, msg, _env_module), do: route(agent, msg, :tell)

  defp dispatch(false, agent, msg, env_module) do
    target = remote_target(agent, env_module: env_module)
    route_to(agent, msg, env_module, target)
  end

  defp route_to(agent, msg, _env_module, nil), do: route(agent, msg, :tell)

  defp route_to(agent, msg, env_module, target) do
    attempt_inject(msg, target, agent, env_module)
  end

  def remote_target(agent, opts \\ []) do
    env_module = Keyword.get(opts, :env_module, El.Infra.Env)
    node_target(agent, env_module.get("EL_NODE"))
  end

  defp node_target(_agent, nil), do: nil
  defp node_target(agent, host), do: :"claude_#{agent}@#{host}"

  defp attempt_inject(msg, target, agent, env_module) do
    context = {msg, target, String.to_atom(agent), agent, env_module}
    dispatch_by_connection(Node.connect(target), context)
  end

  defp dispatch_by_connection(true, {msg, target, process_name, _agent, _env_module}) do
    inject(msg, target, process_name)
  end

  defp dispatch_by_connection(false, {msg, _target, _process_name, agent, env_module}) do
    fail_inject(agent, msg, env_module)
  end

  defp fail_inject(agent, msg, env_module) do
    host = env_module.get("EL_NODE")
    remote_unreachable(agent, host)
    route(agent, msg, :tell)
  end

  def remote_unreachable(agent, host) do
    IO.write(:stderr, "session #{agent} unreachable at #{host}\n")
  end

  defp inject(msg, target, process_name) do
    text = format_text(msg)
    GenServer.cast({process_name, target}, {:inject, text})
  end

  defp format_text(msg) do
    wrap(contains?(msg, "\n"), msg)
  end

  defp wrap(true, msg), do: bracket_paste(msg)
  defp wrap(false, msg), do: finish(control_sequence?(msg), msg)

  defp finish(true, msg), do: msg
  defp finish(false, msg), do: append_return(msg)

  defp bracket_paste(msg), do: "\e[200~#{msg}\e[201~\r"
  defp append_return(msg), do: "#{msg}\r"

  defp control_sequence?(msg) do
    is_special_byte(at(msg, 0))
  end

  defp is_special_byte(nil), do: false
  defp is_special_byte(byte) when byte < 32, do: true
  defp is_special_byte(0x1B), do: true
  defp is_special_byte(_), do: false
end
