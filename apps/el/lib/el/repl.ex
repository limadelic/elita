defmodule El.REPL do
  import Application, only: [ensure_all_started: 1]
  import Elita, only: [spawn: 2]
  import El.Distribution, only: [wait: 1]
  import El.Tunnel, only: [boot: 1, reach: 1]
  import El.Puppet, only: [ask: 2]
  import Agent.Harness, only: [dispatch: 3]
  import El.Sessions, only: [log: 1]
  import IO, only: [read: 2, puts: 1, write: 1]
  import String, only: [trim: 1, split: 3]
  import Utils.World, only: [agents: 0]

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
  defp proceed({:ok, target, pid}, _agent, _puppet), do: loop(target, pid)
  defp handle(_agent, _puppet, ""), do: :ok
  defp handle(_agent, _puppet, "/exit"), do: :stop
  defp handle(agent, puppet, input) when is_pid(puppet) do
    input |> split(" ", parts: 2) |> route(agent, puppet, input)
  end

  defp handle(agent, nil, "log"), do: agent |> log() |> puts()
  defp handle(agent, nil, input), do: dispatch(agent, input, :ask) |> puts()
  defp handle(agent, :undefined, "log"), do: agent |> log() |> puts()
  defp handle(agent, :undefined, input), do: dispatch(agent, input, :ask) |> puts()
  defp route([name, "log"], _a, _p, _i), do: name |> log() |> puts()
  defp route(_x, agent, puppet, input) do
    words = input |> split(" ", parts: 2)
    {response, target, pid} = via(words, puppet, input, agent)
    puts(response)
    result(target, agent, pid)
  end

  defp result(agent, agent, _pid), do: :ok
  defp result(target, _agent, pid), do: {:ok, target, pid}
  defp via([_w], p, i, agent), do: {ask(p, i), agent, p}
  defp via([w, msg], p, _i, agent), do: send(w, msg, p, agent, w in agents())
  defp via(_, p, i, agent), do: {ask(p, i), agent, p}
  defp send(w, msg, p, _agent, true) do
    pid = choose(wait(w), p)
    {ask(pid, msg), w, pid}
  end
  defp send(w, msg, p, agent, false) do
    {ask(p, w <> " " <> msg), agent, p}
  end

  defp choose(nil, default), do: default
  defp choose(:undefined, default), do: default
  defp choose(t, _), do: t
end
