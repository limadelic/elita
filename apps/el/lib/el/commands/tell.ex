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

  def tell(agent, msg, tool \\ nil, opts \\ []) do
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
    target = target(agent, env_module: env)
    mail(target, {agent, msg, tool, env})
  end

  defp mail(nil, {agent, msg, tool, _}) do
    route(agent, msg, :tell, tool)
  end

  defp mail(target, {agent, msg, tool, env}) do
    ctx = {msg, target, to_atom(agent), agent, env, tool}
    act(connect(target), ctx)
  end

  defp act(true, {msg, target, process_name, _agent, _env_module, tool}) do
    inject(msg, target, process_name, tool)
  end

  defp act(false, {msg, _target, _process_name, agent, env_module, tool}) do
    host = env_module.get("EL_NODE")
    unreachable(agent, host)
    route(agent, msg, :tell, tool)
  end

  defp inject(msg, target, process_name, _tool) do
    text = format(msg)
    cast({process_name, target}, {:inject, text})
  end

  def target(agent, opts \\ []) do
    env_module = get(opts, :env_module, El.Infra.Env)
    node(agent, env_module.get("EL_NODE"))
  end

  defp node(_agent, nil), do: nil
  defp node(agent, host), do: :"claude_#{agent}@#{host}"

  def unreachable(agent, host) do
    write(:stderr, "session #{agent} unreachable at #{host}\n")
  end

  defp format(msg) do
    wrap(contains?(msg, "\n"), msg)
  end

  defp wrap(true, msg), do: paste(msg)
  defp wrap(false, msg), do: finish(control?(msg), msg)

  defp finish(true, msg), do: msg
  defp finish(false, msg), do: append(msg)

  defp paste(msg), do: "\e[200~#{msg}\e[201~\r"
  defp append(msg), do: "#{msg}\r"

  defp control?(msg) do
    special?(at(msg, 0))
  end

  defp special?(nil), do: false
  defp special?(byte) when byte < 32, do: true
  defp special?(0x1B), do: true
  defp special?(_), do: false
end
