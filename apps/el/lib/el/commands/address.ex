defmodule El.Commands.Address do
  import Agent.Config, only: [load: 0]
  import Agent.Session, only: [start_link: 1]
  import El.Commands.Lookup, only: [local: 2]
  import Elita, only: [cast: 2]
  import String, only: [downcase: 1]

  def route(recipient, msg, mode \\ :ask) do
    world = world()
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
    ping(entry.name, msg)
  end

  defp handle({:many, _entries}, _recipient, _msg, :ask) do
    IO.puts("ask requires one target")
  end

  defp handle({:many, entries}, _recipient, msg, :tell) do
    Enum.each(entries, fn e -> rouse(e); ping(e.name, msg) end)
  end

  defp ping(agent, msg) do
    normalized = agent |> downcase
    Registry.lookup(ElitaRegistry, normalized) |> fire(agent, msg)
  end
  defp fire([], agent, _msg), do: IO.puts("unknown: #{agent}")
  defp fire(matches, agent, msg), do: Enum.each(matches, fn _ -> cast(agent, msg) end)
  defp rouse(%{kind: :file, name: n, path: p}) do
    stir(asleep?(n), n, p)
  end

  defp rouse(_), do: :ok

  defp stir(false, _name, _folder), do: :ok
  defp stir(true, name, folder) do
    rune = System.get_env("TEST_AGENT_RUNNER") |> grab()
    opts = [name: name, folder: folder]
    start_link(pick(opts, rune))
  end

  defp pick(opts, nil), do: opts
  defp pick(opts, rune), do: Keyword.put(opts, :runner, fn m, f -> apply(rune, :run, [m, f]) end)

  defp grab(nil), do: nil
  defp grab(name), do: test(String.to_atom("Elixir." <> name))

  defp test(atom), do: okay(Code.ensure_loaded?(atom), atom)
  defp okay(true, atom), do: atom
  defp okay(false, _atom), do: nil

  defp asleep?(name) do
    normalized = String.downcase(to_string(name))
    Registry.lookup(ElitaRegistry, normalized) |> Enum.empty?()
  end

  defp world do
    folders = load() |> Enum.map(&entry/1)
    files = Enum.flat_map(folders, &scan/1)
    folders ++ files
  end

  defp entry({name, folder}) do
    %{name: Atom.to_string(name), path: Path.expand(folder), kind: :folder}
  end

  defp scan(%{path: folder}) do
    File.ls!(folder)
    |> Enum.filter(&String.ends_with?(&1, ".exs"))
    |> Enum.map(&file(folder, &1))
  rescue
    _ -> []
  end

  defp file(folder, filename) do
    name = String.trim_trailing(filename, ".exs")
    file_path = Path.join(folder, filename)
    %{name: name, path: folder, file_path: file_path, kind: :file}
  end

  defp cwd do
    File.cwd!() |> trim()
  end

  defp trim("/private" <> rest), do: rest
  defp trim(path), do: path
end
