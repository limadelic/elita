defmodule El.Commands.Ls do
  @moduledoc "Lists agents in the current folder with their registration status."

  import IO, only: [puts: 1]
  import File, only: [ls!: 1]
  import Enum, only: [map: 2, sort_by: 2, each: 2, reject: 2]
  import String, only: [starts_with?: 2]
  alias El.CLI.DaemonConnector

  def execute(opts \\ []) do
    try_daemon_first() || local_execute(opts)
  end

  defp try_daemon_first do
    case DaemonConnector.connect_and_rpc(["ls"], []) do
      :local -> nil
      result -> result
    end
  end

  defp local_execute(opts) do
    cwd = Keyword.get(opts, :cwd, File.cwd!())
    build(cwd) |> show()
  end

  defp build(path) do
    path
    |> ls!()
    |> reject(&hidden/1)
    |> map(&entry(path, &1))
    |> sort_by(& &1.name)
  end

  defp hidden(name) do
    starts_with?(name, ".")
  end

  defp entry(path, name) do
    full = Path.join(path, name)
    %{name: name, path: full, kind: guess_kind(full)}
  end

  defp guess_kind(path) do
    File.dir?(path) |> choose_kind()
  end

  defp choose_kind(true), do: :folder
  defp choose_kind(false), do: :file

  defp show([]), do: puts("no agents")

  defp show(entries) do
    entries |> map(&format/1) |> each(&puts/1)
  end

  defp format(entry) do
    "#{entry.name} #{kind_label(entry.kind)} #{status(entry.name)}"
  end

  defp status(name) do
    Registry.lookup(ElitaRegistry, name) |> map_status()
  end

  defp map_status([_ | _]), do: "active"
  defp map_status([]), do: "asleep"

  defp kind_label(:file), do: "file"
  defp kind_label(:folder), do: "folder"
end
