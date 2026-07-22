#!/usr/bin/env elixir
# Reset daemon agents and tape state between scenarios

node_name = :"elita-cukes@127.0.0.1"

unless Node.alive?() do
  case Node.start(:"reset-#{:erlang.unique_integer([:positive])}@127.0.0.1") do
    {:ok, _} -> nil
    {:error, _} -> nil
  end
end

if Node.connect(node_name) do
  # Terminate all spawned agents via DynamicSupervisor
  try do
    children = :erpc.call(node_name, DynamicSupervisor, :which_children, [Elita.Spawner])
    Enum.each(children, fn {_id, pid, _type, _modules} ->
      :erpc.call(node_name, DynamicSupervisor, :terminate_child, [Elita.Spawner, pid])
    end)
  rescue _ -> nil
  end

  Process.sleep(100)

  # Restart Tape.Writer to reset counter
  try do
    :erpc.call(node_name, Supervisor, :terminate_child, [Tape.Supervisor, Tape.Writer])
    Process.sleep(50)
    :erpc.call(node_name, Supervisor, :restart_child, [Tape.Supervisor, Tape.Writer])
  rescue _ -> nil
  end

  Process.sleep(100)
end

System.halt(0)
