defmodule El.REPL do
  import Application, only: [ensure_all_started: 1]
  import Elita, only: [spawn: 2]
  import El.Tunnel, only: [boot: 1, reach: 1]
  import Agent.Harness, only: [dispatch: 3]
  import El.Sessions, only: [log: 1]
  import El.Repl.Route, only: [route: 4]
  import IO, only: [read: 2, puts: 1, write: 1]
  import String, only: [trim: 1, split: 3]

  def run(agent) do
    ensure_all_started(:elita)
    loop(agent, init(agent))
  end

  defp init(agent) do
    reg() |> settle()
    tape() |> settle()
    boot(agent)
    find(agent)
  end

  defp reg do
    import Registry, only: [start_link: 1]
    start_link(keys: :unique, name: ElitaRegistry)
  end

  defp tape do
    import Tape.Writer, only: [start_link: 1]
    start_link(nil)
  end

  defp find(agent) do
    agent |> reach() |> pick(agent)
  rescue
    _ -> native(agent)
  end

  defp pick(nil, agent), do: native(agent)
  defp pick(:undefined, agent), do: native(agent)
  defp pick(pid, _agent), do: pid

  defp native(agent) do
    import Elita, only: [spawn: 2]
    {:ok, pid} = spawn(agent, [agent])
    settle({:ok, pid})
    pid
  end

  defp settle({:ok, _pid}), do: :ok
  defp settle({:error, {:already_started, _pid}}), do: :ok
  defp settle({:error, _}), do: :ok

  defp loop(agent, puppet) do
    write("#{agent}> ")
    read(:stdio, :line) |> next(agent, puppet)
  end

  defp next(:eof, _agent, _puppet), do: :ok

  defp next(line, agent, puppet) do
    handle(agent, puppet, trim(line)) |> proceed(agent, puppet)
  end

  defp proceed(:stop, _agent, _puppet), do: :ok
  defp proceed(:ok, agent, puppet), do: loop(agent, puppet)

  defp handle(_agent, _puppet, ""), do: :ok
  defp handle(_agent, _puppet, "/exit"), do: :stop

  defp handle(agent, puppet, input) when is_pid(puppet) do
    input |> split(" ", parts: 2) |> route(agent, puppet, input)
  end

  defp handle(agent, nil, "log"), do: agent |> log() |> puts()
  defp handle(agent, nil, input), do: dispatch(agent, input, :ask) |> puts()
  defp handle(agent, :undefined, "log"), do: agent |> log() |> puts()
  defp handle(agent, :undefined, input), do: dispatch(agent, input, :ask) |> puts()
end
