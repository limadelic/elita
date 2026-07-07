defmodule El.Commands.Ask do
  @moduledoc false
  import El.Commands.Address, only: [route: 4]
  import El.Commands.Ask.Remote, only: [ask: 4]
  import El.Commands.Lookup, only: [local: 4]
  import String, only: [contains?: 2]

  alias El.Commands.Tell
  alias El.Distribution

  def execute(agent, msg, tool \\ nil, opts \\ []) do
    Distribution.start()
    {t, o, env} = args(tool, opts)
    ctx = %{agent: agent, msg: msg, tool: t, env: env, opts: o}
    dispatch(ctx, contains?(agent, "@"))
  end

  defp args(tool, _opts) when is_list(tool) do
    env = Keyword.get(tool, :env_module, El.Infra.Env)
    {nil, tool, env}
  end

  defp args(tool, opts) do
    env = Keyword.get(opts, :env_module, El.Infra.Env)
    {tool, opts, env}
  end

  defp dispatch(ctx, true) do
    %{agent: agent, msg: msg, tool: tool} = ctx
    route(agent, msg, :ask, tool)
  end

  defp dispatch(
         %{agent: agent, msg: msg, tool: tool, env: env, opts: opts},
         false
       ) do
    target = Tell.remote_target(agent, env_module: env)
    transmit(target, {agent, msg, tool, env, opts})
  end

  defp transmit(nil, {agent, msg, tool, _, opts}) do
    local(agent, msg, tool, opts)
  end

  defp transmit(target, {agent, msg, tool, env, _}) do
    dial(msg, target, agent, env, tool)
  end

  defp dial(msg, target, agent, env_module, tool) do
    context = {msg, target, String.to_atom(agent), agent, env_module, tool}
    forward(Node.connect(target), context)
  end

  defp forward(
         true,
         {msg, target, process_name, _agent, _env_module, tool}
       ) do
    ask(msg, target, process_name, tool)
  end

  defp forward(
         _result,
         {msg, _target, _process_name, agent, env_module, tool}
       ) do
    fallback(agent, msg, env_module, tool)
  end

  defp fallback(agent, msg, env_module, tool) do
    host = env_module.get("EL_NODE")
    Tell.remote_unreachable(agent, host)
    local(agent, msg, tool, [])
  end
end
