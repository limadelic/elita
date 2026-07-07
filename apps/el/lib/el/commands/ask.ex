defmodule El.Commands.Ask do
  @moduledoc false
  import :binary, only: [at: 2]
  import Elita, only: [start_link: 2, call: 2]
  alias El.Answer
  alias El.Commands.Tell
  alias El.Distribution

  def execute(agent, msg, opts \\ []) do
    Distribution.start()
    env_module = Keyword.get(opts, :env_module, El.Infra.Env)
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
    Answer.collect(120_000)
  end

  defp fail_call(agent, msg, env_module) do
    host = env_module.get("EL_NODE")
    Tell.remote_unreachable(agent, host)
    local(agent, msg)
  end

  defp local(agent, msg) do
    {:ok, _pid} = start_link(agent, [agent])
    result = call(agent, msg)
    IO.puts(result)
  end

  defp format_text(msg) do
    pick_format(String.contains?(msg, "\n"), msg)
  end

  defp pick_format(true, msg), do: bracket_paste(msg)
  defp pick_format(false, msg), do: pick_format_alt(control_sequence?(msg), msg)

  defp pick_format_alt(true, msg), do: msg
  defp pick_format_alt(false, msg), do: append_return(msg)

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
