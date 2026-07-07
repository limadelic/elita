defmodule El.Commands.Ask do
  @moduledoc false
  import Elita, only: [call: 2]
  import String, only: [downcase: 1]
  alias El.Answer
  alias El.Commands.Tell
  alias El.Distribution
  alias El.CLI.DaemonConnector
  alias El.TextFormat

  def execute(agent, msg, opts \\ []) do
    Distribution.start()
    env_module = Keyword.get(opts, :env_module, El.Infra.Env)
    daemon_result = daemon(agent, msg)
    dispatch(daemon_result, agent, msg, env_module)
  end

  defp dispatch(result, _agent, _msg, _env_module) when result != nil do
    result
  end

  defp dispatch(nil, agent, msg, env_module) do
    route(agent, msg, env_module)
  end

  defp daemon(agent, msg) do
    DaemonConnector.connect_and_rpc(["ask", agent, msg], []) |> check()
  end

  defp check(:local), do: nil
  defp check(result), do: result

  defp route(agent, msg, env_module) do
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
    text = TextFormat.format(msg)
    GenServer.cast({process_name, target}, {:inject, text})
    Answer.collect(30_000)
  end

  defp fail_call(agent, msg, env_module) do
    host = env_module.get("EL_NODE")
    Tell.remote_unreachable(agent, host)
    local(agent, msg)
  end

  defp local(agent, msg) do
    normalized = agent |> downcase
    Registry.lookup(ElitaRegistry, normalized) |> handle_lookup(agent, msg)
  end

  defp handle_lookup([], agent, _msg), do: IO.puts("unknown: #{agent}")

  defp handle_lookup([{_pid, _meta}], agent, msg) do
    call(agent, msg) |> IO.puts()
  end
end
