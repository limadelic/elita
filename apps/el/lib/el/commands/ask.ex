defmodule El.Commands.Ask do
  @moduledoc false
  import :binary, only: [at: 2]
  import String, only: [contains?: 2]
  import El.Commands.Address, only: [route: 4]
  import El.Commands.Lookup, only: [local: 4]
  alias El.Answer
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

  defp dispatch(%{agent: agent, msg: msg, tool: tool, env: env, opts: opts}, false) do
    target = Tell.remote_target(agent, env_module: env)
    send_via(target, {agent, msg, tool, env, opts})
  end

  defp send_via(nil, {agent, msg, tool, _, opts}) do
    local(agent, msg, tool, opts)
  end

  defp send_via(target, {agent, msg, tool, env, _}) do
    attempt_call(msg, target, agent, env, tool)
  end

  defp attempt_call(msg, target, agent, env_module, tool) do
    context = {msg, target, String.to_atom(agent), agent, env_module, tool}
    dispatch_by_connection(Node.connect(target), context)
  end

  defp dispatch_by_connection(true, {msg, target, process_name, _agent, _env_module, tool}) do
    remote_ask(msg, target, process_name, tool)
  end

  defp dispatch_by_connection(false, {msg, _target, _process_name, agent, env_module, tool}) do
    fail_call(agent, msg, env_module, tool)
  end

  defp remote_ask(msg, target, process_name, tool) do
    with_tap(target, process_name, fn ->
      answer = get_answer(msg, target, process_name)
      IO.puts(answer)
    end, tool)
  end

  defp with_tap(target, process_name, fun, _tool) do
    :ok = GenServer.call({process_name, target}, {:tap, self()})
    result = fun.()
    :ok = GenServer.call({process_name, target}, {:untap, self()})
    result
  end

  defp fail_call(agent, msg, env_module, tool) do
    host = env_module.get("EL_NODE")
    Tell.remote_unreachable(agent, host)
    local(agent, msg, tool, [])
  end

  defp get_answer(msg, target, process_name) do
    text = format_text(msg)
    ref = make_ref()
    reply_to = {ref, self()}
    GenServer.cast({process_name, target}, {:inject, text, reply_to: reply_to})
    Answer.wait_reply(ref, 30_000)
  end
  defp format_text(msg), do: apply_format(String.contains?(msg, "\n"), msg)

  defp apply_format(true, msg), do: "\e[200~#{msg}\e[201~\r"
  defp apply_format(false, msg), do: maybe_return(special_byte?(at(msg, 0)), msg)

  defp maybe_return(true, msg), do: msg
  defp maybe_return(false, msg), do: "#{msg}\r"

  defp special_byte?(nil), do: false
  defp special_byte?(0x1B), do: true
  defp special_byte?(b) when b < 32, do: true
  defp special_byte?(_), do: false
end
