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
    wake_if_needed(entry)
    local(entry.name, msg)
  end

  defp handle({:many, _}, _recipient, _msg) do
    IO.puts("ask requires one target")
  end

  defp wake_if_needed(%{kind: :file, name: n, path: p}) do
    handle_wake(not_live?(n), n, p)
  end

  defp wake_if_needed(_), do: :ok

  defp handle_wake(true, name, folder), do: start_session(name, folder)
  defp handle_wake(false, _, _), do: :ok

  defp start_session(name, folder) do
    opts = [name: name, folder: folder]
    runner = maybe_runner()
    start_link(add_runner_to_opts(opts, runner))
  end

  defp add_runner_to_opts(opts, nil), do: opts
  defp add_runner_to_opts(opts, mod) do
    Keyword.put(opts, :runner, fn m, f -> apply(mod, :run, [m, f]) end)
  end

  defp maybe_runner do
    env_name = System.get_env("TEST_AGENT_RUNNER")
    check_runner(env_name)
  end

  defp check_runner(nil), do: nil
  defp check_runner(name) do
    atom = String.to_atom("Elixir." <> name)
    verify_runner(atom)
  end

  defp verify_runner(atom), do: check_loaded(atom, Code.ensure_loaded?(atom))
  defp check_loaded(atom, true), do: atom
  defp check_loaded(_atom, false), do: nil

  defp not_live?(name) do
    normalized = String.downcase(to_string(name))
    Registry.lookup(ElitaRegistry, normalized) |> Enum.empty?()
  end

  defp world do
    folders = load() |> Enum.map(&folder_entry/1)
    files = Enum.flat_map(folders, &scan_files/1)
    folders ++ files
  end

  defp folder_entry({name, folder}) do
    %{name: Atom.to_string(name), path: Path.expand(folder), kind: :folder}
  end

  defp scan_files(%{path: folder}) do
    File.ls!(folder)
    |> Enum.filter(&String.ends_with?(&1, ".exs"))
    |> Enum.map(&file_entry(folder, &1))
  rescue
    _ -> []
  end

  defp file_entry(folder, filename) do
    name = String.trim_trailing(filename, ".exs")
    file_path = Path.join(folder, filename)
    %{name: name, path: folder, file_path: file_path, kind: :file}
  end

  defp cwd do
    File.cwd!() |> strip_private()
  end

  defp strip_private("/private" <> rest), do: rest
  defp strip_private(path), do: path
end
