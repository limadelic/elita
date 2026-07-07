defmodule El.Commands.Address do
  import Agent.Session, only: [start_link: 1]
  import El.Commands.Lookup, only: [local: 2]
  import String, only: [downcase: 1]
  import El.Commands.Address.World, only: [build: 0, cwd: 0]

  def route(recipient, msg, mode \\ :ask) do
    world = build()
    cwd = cwd()
    result = Resolver.resolve(recipient, world, cwd)
    handle(result, recipient, msg, mode)
  end

  defp handle({:error, :unknown}, recipient, _msg, _mode) do
    IO.puts("unknown: #{recipient}")
  end

  defp handle({:ok, entry}, _recipient, msg, :ask) do
    rouse(entry)
    local(entry.name, msg)
  end

  defp handle({:ok, entry}, _recipient, msg, :tell) do
    rouse(entry)
    tell(entry.name, msg)
  end

  defp handle({:many, _entries}, _recipient, _msg, :ask) do
    IO.puts("ask requires one target")
  end

  defp handle({:many, entries}, _recipient, msg, :tell) do
    unique = Enum.uniq_by(entries, &{&1.name, &1.path})
    blast(unique)
    echo(unique, msg)
  end

  defp blast(entries), do: Enum.each(entries, &rouse/1)
  defp echo(entries, msg), do: Enum.each(entries, fn e -> tell(e.name, msg) end)

  defp tell(agent, msg) do
    agent |> downcase |> find(msg)
  end

  defp find(normalized, msg) do
    Registry.lookup(ElitaRegistry, normalized) |> dispatch(msg)
  end

  defp dispatch([], _msg), do: :ok
  defp dispatch(pids, msg) do
    Enum.each(pids, fn {pid, meta} -> send(pid, meta[:kind], msg) end)
  end

  defp send(pid, :native, msg), do: GenServer.cast(pid, {:act, msg})
  defp send(pid, _, msg), do: GenServer.cast(pid, {:cast, msg})
  defp rouse(%{kind: :file, name: n, path: p, file_path: fp}) do
    stir(asleep?(n), n, p, fp)
  end

  defp rouse(%{kind: :file, name: n, path: p}) do
    stir(asleep?(n), n, p, nil)
  end

  defp rouse(%{kind: :folder, name: n, path: p, file_path: fp}) do
    stir(asleep?(n), n, p, fp)
  end

  defp rouse(%{kind: :folder, name: n, path: p}) do
    stir(asleep?(n), n, p, nil)
  end

  defp rouse(_), do: :ok

  defp stir(false, _name, _folder, _self), do: :ok
  defp stir(true, name, folder, self) do
    rune = System.get_env("TEST_AGENT_RUNNER") |> pick()
    opts = [name: name, folder: folder, self: self]
    start_link(wire(opts, rune))
  end

  defp pick(nil), do: nil
  defp pick(name), do: test(String.to_atom("Elixir." <> name))

  defp test(atom), do: okay(Code.ensure_loaded?(atom), atom)

  defp okay(true, atom), do: atom
  defp okay(false, _atom), do: nil

  defp wire(opts, nil), do: opts
  defp wire(opts, rune) do
    Keyword.put(opts, :runner, fn m, f -> apply(rune, :run, [m, f]) end)
  end

  defp asleep?(name) do
    normalized = String.downcase(to_string(name))
    Registry.lookup(ElitaRegistry, normalized) |> Enum.empty?()
  end
end
