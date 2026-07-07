defmodule El.Commands.Ask do
  @moduledoc false
  import :binary, only: [at: 2]
  import Elita, only: [call: 2]
  import String, only: [downcase: 1, contains?: 2]
  alias El.Answer
  alias El.Commands.Tell
  alias El.Distribution

  def execute(agent, msg, opts \\ []) do
    Distribution.start()
    env_module = Keyword.get(opts, :env_module, El.Infra.Env)
    route_request(contains?(agent, "@"), agent, msg, env_module)
  end

  defp route_request(true, agent, msg, _env_module) do
    El.Commands.Address.route(agent, msg)
  end

  defp route_request(false, agent, msg, env_module) do
    route(agent, msg, env_module)
  end

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
    text = format_text(msg)
    GenServer.cast({process_name, target}, {:inject, text})
    Answer.collect(30_000)
  end

  defp fail_call(agent, msg, env_module) do
    host = env_module.get("EL_NODE")
    Tell.remote_unreachable(agent, host)
    local(agent, msg)
  end

  defp local(agent, msg) do
    local_by_name(agent, msg)
  end

  def local_by_name(agent, msg) do
    agent |> downcase |> lookup_and_call(agent, msg)
  end

  defp lookup_and_call(normalized, agent, msg) do
    Registry.lookup(ElitaRegistry, normalized) |> dispatch(agent, msg)
  end

  defp dispatch([], agent, _msg), do: IO.puts("unknown: #{agent}")
  defp dispatch([{_pid, _meta}], agent, msg), do: call(agent, msg) |> IO.puts()

  defp format_text(msg) do
    cond do
      String.contains?(msg, "\n") -> "\e[200~#{msg}\e[201~\r"
      control_sequence?(msg) -> msg
      true -> "#{msg}\r"
    end
  end

  defp control_sequence?(msg) do
    b = at(msg, 0)
    b && (b < 32 || b == 0x1B)
  end
end
