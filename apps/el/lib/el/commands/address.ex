defmodule El.Commands.Address do
  import Agent.Session, only: [start_link: 1]
  import El.Commands.Lookup, only: [local: 4]
  import String, only: [downcase: 1]
  import El.Commands.Address.World, only: [build: 0, cwd: 0]

  def route(recipient, msg, mode \\ :ask, tool \\ nil) do
    world = build()
    cwd = cwd()
    result = Resolver.resolve(recipient, world, cwd)
    handle(result, recipient, msg, mode, tool)
  end

  defp handle({:error, :unknown}, recipient, _msg, _mode, _tool) do
    IO.puts("unknown: #{recipient}")
  end

  defp handle({:ok, entry}, _recipient, msg, :ask, tool) do
    rouse(entry)
    local(entry.name, msg, tool, [])
  end

  defp handle({:ok, entry}, _recipient, msg, :tell, tool) do
    rouse(entry)
    tell(entry.name, msg, tool)
  end

  defp handle({:many, _entries}, _recipient, _msg, :ask, _tool) do
    IO.puts("ask requires one target")
  end

  defp handle({:many, entries}, _recipient, msg, :tell, tool) do
    unique = Enum.uniq_by(entries, &{&1.name, &1.path})
    blast(unique)
    echo(unique, msg, tool)
  end

  defp blast(entries), do: Enum.each(entries, &rouse/1)
  defp echo(entries, msg, tool), do: Enum.each(entries, fn e -> tell(e.name, msg, tool) end)
  defp tell(agent, msg, tool), do: agent |> downcase |> find(msg, tool)
  defp find(n, msg, nil), do: lookup(n) |> dispatch(msg)
  defp find(n, msg, tool), do: lookup("#{n}:#{tool}") |> fallback(n) |> dispatch(msg)
  defp lookup(key), do: Registry.lookup(ElitaRegistry, key)
  defp fallback([], key), do: lookup(key)
  defp fallback(r, _), do: r
  defp dispatch([], _msg), do: :ok
  defp dispatch(pids, msg), do: Enum.each(pids, fn {pid, meta} -> send(pid, meta[:kind], msg) end)
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
  defp pick(name) do
    atom = String.to_atom("Elixir." <> name)
    resolve_atom(Code.ensure_loaded?(atom), atom)
  end

  defp resolve_atom(true, atom), do: atom
  defp resolve_atom(false, _), do: nil

  defp wire(opts, nil), do: opts
  defp wire(opts, rune) do
    Keyword.put(opts, :runner, fn m, f -> apply(rune, :run, [m, f]) end)
  end

  defp asleep?(name) do
    String.downcase(to_string(name)) |> lookup_empty?()
  end

  defp lookup_empty?(normalized) do
    Registry.lookup(ElitaRegistry, normalized) |> Enum.empty?()
  end
end
