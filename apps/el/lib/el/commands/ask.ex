defmodule El.Commands.Ask do
  @moduledoc false
  import Elita, only: [start_link: 2, call: 2]
  alias El.Distribution
  alias El.Commands.Tell

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

  defp dispatch_by_connection(true, {_msg, _target, _process_name, _agent, _env_module}) do
    IO.puts("ask: no answer channel yet")
    System.halt(1)
  end

  defp dispatch_by_connection(false, {msg, _target, _process_name, agent, env_module}) do
    fail_call(agent, msg, env_module)
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
end
