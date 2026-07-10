defmodule El.REPL do
  import Application, only: [ensure_all_started: 1]
  import Elita, only: [spawn: 2]
  import El.Distribution, only: [start: 0]
  import El.Puppet, only: [ask: 2]
  import Agent.Harness, only: [dispatch: 3]
  import IO, only: [read: 2, puts: 1, write: 1]
  import String, only: [trim: 1]

  def run(agent) do
    ensure_all_started(:elita)
    puppet = init(agent)
    loop(agent, puppet)
  end

  defp init(agent) do
    setup()
    boot()
    find(agent)
  end

  defp setup do
    import Registry, only: [start_link: 1]
    start_link(keys: :unique, name: ElitaRegistry) |> settle()
    tape() |> settle()
  end

  defp boot do
    start()
  rescue
    _ -> :ok
  end

  defp find(agent) do
    {agent, :puppet} |> :global.whereis_name() |> pick(agent)
  rescue
    _ -> native(agent)
  end

  defp pick(:undefined, agent), do: native(agent)
  defp pick(pid, _agent), do: pid

  defp native(agent) do
    import Elita, only: [spawn: 2]
    spawn(agent, [agent]) |> settle()
    nil
  end

  defp tape do
    import Tape.Writer, only: [start_link: 1]
    start_link(nil)
  end

  defp settle({:ok, _pid}), do: :ok
  defp settle({:error, {:already_started, _pid}}), do: :ok
  defp settle({:error, _}), do: :ok

  defp loop(agent, puppet) do
    prompt(agent)
    read(:stdio, :line) |> process(agent, puppet)
  end

  defp prompt(agent), do: write("#{agent}> ")

  defp process(:eof, _agent, _puppet), do: :ok

  defp process(line, agent, puppet) do
    handle(agent, puppet, trim(line)) |> proceed(agent, puppet)
  end

  defp proceed(:stop, _agent, _puppet), do: :ok
  defp proceed(:ok, agent, puppet), do: loop(agent, puppet)

  defp handle(_agent, _puppet, ""), do: :ok

  defp handle(_agent, _puppet, "/exit"), do: :stop

  defp handle(agent, puppet, input) when is_pid(puppet) do
    route(agent, puppet, input) |> puts()
  end

  defp handle(agent, nil, input) do
    dispatch(agent, input, :ask) |> puts()
  end

  defp route(a, p, i), do: route(a, p, i, String.split(i, " ", parts: 2))
  defp route(_, p, i, [_w]), do: ask(p, i)
  defp route(a, p, _i, [w, r]) when a != w, do: dispatch(p, w, r, lookup(w))
  defp route(_, p, _, [w, r]), do: ask(p, w <> " " <> r)
  defp dispatch(_, _, r, pid) when is_pid(pid), do: ask(pid, r)
  defp dispatch(p, w, r, _), do: ask(p, w <> " " <> r)

  defp lookup(word) do
    :global.whereis_name({word, :puppet})
  rescue
    _ -> nil
  end
end
