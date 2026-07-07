defmodule El.Commands.Spawn do
  @moduledoc false
  import String, only: [downcase: 1]
  import Agent.Session, only: [start_link: 1]
  import El.Commands.Address.World, only: [build: 0, cwd: 0]
  alias El.Distribution

  def execute(session, agent) do
    Distribution.start()
    world = build()
    cwd = cwd()
    result = Resolver.resolve(agent, world, cwd)
    handle(result, session, agent)
  end

  defp handle({:error, :unknown}, _session, agent) do
    IO.puts("error: unknown agent: #{agent}")
  end

  defp handle({:ok, entry}, session, _agent) do
    boot(entry, session)
  end

  defp handle({:many, _entries}, _session, _agent) do
    IO.puts("error: ambiguous agent")
  end

  defp boot(entry, session) do
    key = downcase(session)
    check(Registry.lookup(ElitaRegistry, key), entry, session)
  end

  defp check([], entry, session), do: rouse(entry, session)
  defp check([_ | _], _entry, session), do: IO.puts("error: session name already taken: #{session}")

  defp rouse(%{kind: :file, path: p, file_path: fp}, n) do
    stir(n, p, fp)
  end

  defp rouse(%{kind: :file, path: p}, n) do
    stir(n, p, nil)
  end

  defp rouse(%{kind: :folder, path: p, file_path: fp}, n) do
    stir(n, p, fp)
  end

  defp rouse(%{kind: :folder, path: p}, n) do
    stir(n, p, nil)
  end

  defp rouse(_entry, _session), do: :ok

  defp stir(session, folder, self) do
    rune = System.get_env("TEST_AGENT_RUNNER") |> pick()
    opts = [name: session, folder: folder, self: self]
    start_link(wire(opts, rune))
  end

  defp pick(nil), do: nil
  defp pick(name) do
    atom = String.to_atom("Elixir." <> name)
    exist(Code.ensure_loaded?(atom), atom)
  end

  defp exist(true, atom), do: atom
  defp exist(false, _), do: nil

  defp wire(opts, nil), do: opts
  defp wire(opts, rune) do
    Keyword.put(opts, :runner, fn m, f -> apply(rune, :run, [m, f]) end)
  end
end
