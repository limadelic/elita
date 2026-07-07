defmodule El.Commands.Address do
  import Agent.Config, only: [load: 0]
  import Agent.Session, only: [start_link: 1]
  import El.Commands.Lookup, only: [local: 2]

  def route(recipient, msg) do
    world = world()
    cwd = cwd()
    result = Resolver.resolve(recipient, world, cwd)
    handle(result, recipient, msg)
  end

  defp handle({:error, :unknown}, recipient, _msg) do
    IO.puts("unknown: #{recipient}")
  end

  defp handle({:ok, entry}, _recipient, msg) do
    rouse(entry)
    local(entry.name, msg)
  end

  defp handle({:many, _}, _recipient, _msg) do
    IO.puts("ask requires one target")
  end

  defp rouse(%{kind: :file, name: n, path: p}) do
    stir(asleep?(n), n, p)
  end

  defp rouse(_), do: :ok

  defp stir(true, name, folder), do: boot(name, folder)
  defp stir(false, _, _), do: :ok

  defp boot(name, folder) do
    opts = [name: name, folder: folder]
    rune = runner()
    start_link(mix(opts, rune))
  end

  defp mix(opts, nil), do: opts
  defp mix(opts, mod) do
    Keyword.put(opts, :runner, fn m, f -> apply(mod, :run, [m, f]) end)
  end

  defp runner do
    env_name = System.get_env("TEST_AGENT_RUNNER")
    fetch(env_name)
  end

  defp fetch(nil), do: nil
  defp fetch(name) do
    atom = String.to_atom("Elixir." <> name)
    test(atom)
  end

  defp test(atom), do: okay(atom, Code.ensure_loaded?(atom))
  defp okay(atom, true), do: atom
  defp okay(_atom, false), do: nil

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
