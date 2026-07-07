defmodule El.Commands.Tell do
  @moduledoc false
  import :binary, only: [at: 2]
  import El.Commands.Address, only: [route: 4]
  import El.Distribution, only: [start: 0]
  import GenServer, only: [cast: 2]
  import IO, only: [write: 2]
  import Keyword, only: [get: 3]
  import Node, only: [connect: 1]
  import String, only: [contains?: 2, to_atom: 1]

  def execute(agent, msg, tool \\ nil, opts \\ []) do
    start()
    {t, o, env} = args(tool, opts)
    ctx = %{agent: agent, msg: msg, tool: t, env: env, opts: o}
    dispatch(ctx, contains?(agent, "@"))
  end

  defp args(tool, _opts) when is_list(tool) do
    env = get(tool, :env_module, El.Infra.Env)
    {nil, tool, env}
  end

  defp args(tool, opts) do
    env = get(opts, :env_module, El.Infra.Env)
    {tool, opts, env}
  end

  defp dispatch(ctx, true) do
    %{agent: agent, msg: msg, tool: tool} = ctx
    route(agent, msg, :tell, tool)
  end

  defp dispatch(%{agent: agent, msg: msg, tool: tool, env: env}, false) do
    target = remote_target(agent, env_module: env)
    send_via(target, {agent, msg, tool, env})
  end

  defp send_via(nil, {agent, msg, tool, _}) do
    route(agent, msg, :tell, tool)
  end

  defp send_via(target, {agent, msg, tool, env}) do
    ctx = {msg, target, to_atom(agent), agent, env, tool}
    act(connect(target), ctx)
  end

  defp act(true, {msg, target, process_name, _agent, _env_module, tool}) do
    inject(msg, target, process_name, tool)
  end

  defp act(false, {msg, _target, _process_name, agent, env_module, tool}) do
    host = env_module.get("EL_NODE")
    remote_unreachable(agent, host)
    route(agent, msg, :tell, tool)
  end

  defp inject(msg, target, process_name, _tool) do
    text = format_text(msg)
    cast({process_name, target}, {:inject, text})
  end

  def remote_target(agent, opts \\ []) do
    env_module = get(opts, :env_module, El.Infra.Env)
    node_target(agent, env_module.get("EL_NODE"))
  end

  defp node_target(_agent, nil), do: nil
  defp node_target(agent, host), do: :"claude_#{agent}@#{host}"

  def remote_unreachable(agent, host) do
    write(:stderr, "session #{agent} unreachable at #{host}\n")
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
