defmodule El.Commands.Address do
  import Agent.Config, only: [load: 0]
  import Agent.Session, only: [start_link: 1]
  import El.Commands.Lookup, only: [local: 2]
  import Enum, only: [each: 2]

  def route(recipient, msg, mode \\ :ask) do
    world = world()
    cwd = cwd()
    result = Resolver.resolve(recipient, world, cwd)
    handle(result, recipient, msg, mode)
  end

  defp handle({:error, :unknown}, recipient, _msg, _mode) do
    IO.puts("unknown: #{recipient}")
  end

  defp handle({:ok, entry}, _recipient, msg, _mode) do
    send_to(entry, msg)
  end

  defp handle({:many, _entries}, _recipient, _msg, :ask) do
    IO.puts("ask requires one target")
  end

  defp handle({:many, entries}, _recipient, msg, :tell) do
    each(entries, &send_to(&1, msg))
  end

  defp send_to(entry, msg) do
    rouse(entry)
    local(entry.name, msg)
  end

  defp rouse(%{kind: :file, name: n, path: p}) do
    boot_if_asleep(n, p)
  end

  defp rouse(_), do: :ok

  defp boot_if_asleep(name, folder) do
    start_session(asleep?(name), name, folder)
  end

  defp start_session(false, _name, _folder), do: :ok

  defp start_session(true, name, folder) do
    runner = runner_mod(System.get_env("TEST_AGENT_RUNNER"))
    opts = [name: name, folder: folder]
    opts = add_runner(opts, runner)
    start_link(opts)
  end

  defp add_runner(opts, nil), do: opts

  defp add_runner(opts, runner) do
    Keyword.put(opts, :runner, fn m, f -> apply(runner, :run, [m, f]) end)
  end

  defp runner_mod(nil), do: nil
  defp runner_mod(name), do: get_runner(String.to_atom("Elixir." <> name))

  defp get_runner(atom), do: pick_module(Code.ensure_loaded?(atom), atom)
  defp pick_module(true, atom), do: atom
  defp pick_module(false, _atom), do: nil

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
