defmodule El.Commands.Tell do
  @moduledoc false
  import String, only: [contains?: 2]
  import :binary, only: [at: 2]
  import El.Commands.Address, only: [route: 4]
  alias El.Distribution

  def execute(agent, msg, tool \\ nil, opts \\ []) do
    Distribution.start()
    {actual_tool, actual_opts, env_module} = parse_args(tool, opts)
    ctx = build_ctx(agent, msg, actual_tool, env_module, actual_opts)
    dispatch(ctx, contains?(agent, "@"))
  end

  defp parse_args(tool, opts) when is_list(tool) do
    env_module = Keyword.get(tool, :env_module, El.Infra.Env)
    {nil, tool, env_module}
  end

  defp parse_args(tool, opts) do
    env_module = Keyword.get(opts, :env_module, El.Infra.Env)
    {tool, opts, env_module}
  end

  defp build_ctx(agent, msg, tool, env, opts) do
    %{agent: agent, msg: msg, tool: tool, env: env, opts: opts}
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
    ctx = {msg, target, String.to_atom(agent), agent, env, tool}
    handle_inject(Node.connect(target), ctx)
  end

  defp handle_inject(true, {msg, target, process_name, _agent, _env_module, tool}) do
    inject(msg, target, process_name, tool)
  end

  defp handle_inject(false, {msg, _target, _process_name, agent, env_module, tool}) do
    fail_inject(agent, msg, env_module, tool)
  end

  defp fail_inject(agent, msg, env_module, tool) do
    host = env_module.get("EL_NODE")
    remote_unreachable(agent, host)
    route(agent, msg, :tell, tool)
  end

  defp inject(msg, target, process_name, _tool) do
    text = format_text(msg)
    GenServer.cast({process_name, target}, {:inject, text})
  end

  def remote_target(agent, opts \\ []) do
    env_module = Keyword.get(opts, :env_module, El.Infra.Env)
    node_target(agent, env_module.get("EL_NODE"))
  end

  defp node_target(_agent, nil), do: nil
  defp node_target(agent, host), do: :"claude_#{agent}@#{host}"

  def remote_unreachable(agent, host) do
    IO.write(:stderr, "session #{agent} unreachable at #{host}\n")
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
