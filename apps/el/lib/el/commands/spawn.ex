defmodule El.Commands.Spawn do
  @moduledoc false
  import Agent.Session, only: [start_link: 1]
  import El.Commands.Address.World, only: [build: 0, cwd: 0]
  import Resolver, only: [resolve: 3]
  import String, only: [to_atom: 1]
  import El.Distribution, only: [start: 0]
  import IO, only: [puts: 1]
  import Registry, only: [lookup: 2]
  import Application
  import Code, only: [ensure_loaded?: 1]
  import Keyword, only: [put: 3]
  import Utils.Normalize, only: [name: 1]
  import System, only: [get_env: 1]
  import El.Commands.Rouse, only: [native: 3]

  def spawn(session, agent) do
    start()
    handle(resolve(agent, build(), cwd()), session, agent)
  end

  defp handle({:error, :unknown}, _session, agent) do
    puts("error: unknown agent: #{agent}")
  end

  defp handle({:ok, entry}, session, _agent) do
    boot(entry, session)
  end

  defp handle({:many, _entries}, _session, _agent) do
    puts("error: ambiguous agent")
  end

  defp boot(entry, session) do
    key = name(session)
    check(lookup(ElitaRegistry, key), entry, session)
  end

  defp check([], entry, session), do: rouse(entry, session)

  defp check([_ | _], _entry, session),
    do: puts("error: session name already taken: #{session}")

  defp rouse(%{native: true, name: config}, n) do
    native(n, config, tape())
  end

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
    rune = get_env(:el, :runner) |> pick()
    opts = [name: session, folder: folder, self: self, tape_env: tape()]
    start_link(wire(opts, rune))
  end

  defp tape,
    do: %{
      tape: get_env("TAPE"),
      cassette: get_env("CASSETTE"),
      cassette_dir: get_env("CASSETTE_DIR")
    }

  defp pick(nil), do: nil

  defp pick(n) do
    atom = to_atom("Elixir." <> n)
    exist(ensure_loaded?(atom), atom)
  end

  defp exist(true, atom), do: atom
  defp exist(false, _), do: nil

  defp wire(opts, nil), do: opts

  defp wire(opts, rune) do
    put(opts, :runner, fn m, f, s -> apply(rune, :run, [m, f, s]) end)
  end
end
