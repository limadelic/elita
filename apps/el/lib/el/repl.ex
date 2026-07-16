defmodule El.REPL do
  import Application, only: [ensure_all_started: 1]
  import Elita, only: [spawn: 2]
  import El.Distribution, only: [wait: 1]
  import El.Tunnel, only: [boot: 1, reach: 1]
  import El.Puppet, only: [ask: 2]
  import Agent.Harness, only: [dispatch: 3]
  import El.Log.Reply, only: [handle: 2]
  import IO, only: [read: 2, puts: 1, write: 1]
  import String, only: [trim: 1, split: 3, starts_with?: 2]
  import File, only: [ls: 1, read!: 1]
  import Path, only: [expand: 1, join: 2]
  import Enum, only: [filter: 2, sort: 1]
  import List, only: [last: 1]
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
    spawn(agent, [agent]) |> settle()
    nil
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
  defp route([name, "log"], _a, _p, _i), do: name |> log() |> puts()
  defp route(_x, _agent, puppet, input) do
    {response, target} = input |> split(" ", parts: 2) |> via(puppet, input)
    handle(response, target)
  end
  defp via([_w], p, i), do: {ask(p, i), from(p)}
  defp via([w, _], p, i), do: {ask(choose(wait(w), p), i), w}
  defp via(_, p, i), do: {ask(p, i), from(p)}
  defp from(pid) when is_pid(pid), do: "el"
  defp from(_), do: "el"
  defp choose(nil, default), do: default
  defp choose(t, _), do: t
  defp log(""), do: ""
  defp log(agent) do
    expand("~/.elita/sessions") |> ls() |> open(agent)
  rescue
    _ -> ""
  end
  defp open({:ok, f}, agent) do
    f |> filter(&starts_with?(&1, "#{agent}_")) |> sort() |> last() |> load(agent)
  end
  defp open({:error, _}, _agent), do: ""
  defp load(nil, _agent), do: ""
  defp load(file, _agent) do
    expand("~/.elita/sessions") |> join(file) |> read!()
  end
end
