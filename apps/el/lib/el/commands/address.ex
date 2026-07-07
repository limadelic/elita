defmodule El.Commands.Address do
  import Agent.Config, only: [load: 0]
  import Agent.Session, only: [start_link: 1]
  import El.Commands.Lookup, only: [local: 2]
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
    send_tell(entry.name, msg)
  end

  defp handle({:many, _entries}, _recipient, _msg, :ask) do
    IO.puts("ask requires one target")
  end

  defp handle({:many, entries}, _recipient, msg, :tell) do
    entries
    |> Enum.uniq_by(&{&1.name, &1.path})
    |> Enum.each(fn e -> rouse(e) end)
    entries
    |> Enum.uniq_by(&{&1.name, &1.path})
    |> Enum.each(fn e -> send_tell(e.name, msg) end)
  end

  defp send_tell(agent, msg) do
    agent |> downcase |> lookup_and_dispatch(msg)
  end

  defp lookup_and_dispatch(normalized, msg) do
    Registry.lookup(ElitaRegistry, normalized) |> dispatch(msg)
  end

  defp dispatch([], _msg), do: :ok
  defp dispatch(pids, msg) do
    Enum.each(pids, fn {pid, meta} -> cast_msg(pid, meta[:kind], msg) end)
  end

  defp cast_msg(pid, :native, msg), do: GenServer.cast(pid, {:act, msg})
  defp cast_msg(pid, _, msg), do: GenServer.cast(pid, {:cast, msg})
  defp rouse(%{kind: :file, name: n, path: p}) do
    stir(asleep?(n), n, p)
  end

  defp rouse(_), do: :ok

  defp stir(false, _name, _folder), do: :ok
  defp stir(true, name, folder) do
    runner = System.get_env("TEST_AGENT_RUNNER") |> grab() || stub_runner()
    start_link([name: name, folder: folder, runner: runner])
  end

  defp stub_runner do
    fn _msg, _folder -> "stub response" end
  end

  defp grab(nil), do: nil
  defp grab(name) do
    wrap_runner(String.to_atom(name))
  rescue
    _ -> nil
  end

  defp wrap_runner(atom) do
    if Code.ensure_compiled?(atom) && Kernel.function_exported?(atom, :run, 2) do
      fn m, f -> apply(atom, :run, [m, f]) end
    else
      nil
    end
  end

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
