defmodule El.Commands.Ask do
  @moduledoc false
  import :binary, only: [at: 2]
  import String, only: [contains?: 2]
  import El.Commands.Address, only: [route: 2]
  import El.Commands.Lookup, only: [local: 2]
  alias El.Answer
  alias El.Commands.Tell
  alias El.Distribution

  def execute(agent, msg, opts \\ []) do
    Distribution.start()
    env_module = Keyword.get(opts, :env_module, El.Infra.Env)
    dispatch(contains?(agent, "@"), agent, msg, env_module)
  end

  defp dispatch(true, agent, msg, _env_module), do: route(agent, msg)
  defp dispatch(false, agent, msg, env_module), do: via_route(agent, msg, env_module)

  defp via_route(agent, msg, env_module) do
    target = Tell.remote_target(agent, env_module: env_module)
    route_to(agent, msg, env_module, target)
  end

  defp route_to(agent, msg, _env_module, nil), do: local(agent, msg)
  defp route_to(agent, msg, env_module, target) do
    attempt_call(msg, target, agent, env_module)
  end

  defp attempt_call(msg, target, agent, env_module) do
    context = {msg, target, String.to_atom(agent), agent, env_module}
    dispatch_by_connection(Node.connect(target), context)
  end

  defp dispatch_by_connection(true, {msg, target, process_name, _agent, _env_module}) do
    remote_ask(msg, target, process_name)
  end

  defp dispatch_by_connection(false, {msg, _target, _process_name, agent, env_module}) do
    fail_call(agent, msg, env_module)
  end

  defp remote_ask(msg, target, process_name) do
    with_tap(target, process_name, fn ->
      answer = get_answer(msg, target, process_name)
      IO.puts(answer)
    end)
  end

  defp with_tap(target, process_name, fun) do
    :ok = GenServer.call({process_name, target}, {:tap, self()})
    result = fun.()
    :ok = GenServer.call({process_name, target}, {:untap, self()})
    result
  end

  defp get_answer(msg, target, process_name) do
    text = format_text(msg)
    GenServer.cast({process_name, target}, {:inject, text})
    Answer.collect(30_000)
  end

  defp fail_call(agent, msg, env_module) do
    host = env_module.get("EL_NODE")
    Tell.remote_unreachable(agent, host)
    local(agent, msg)
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
