defmodule El.Command.Ls do
  @moduledoc false

  import IO, only: [puts: 1]
  import System, only: [get_env: 1]
  import Process, only: [sleep: 1]
  import El.Distribution, only: [start: 0]
  import El.Command.Ls.Query, only: [fetch: 1]
  import El.Command.Ls.Boot, only: [spawn: 0]
  import El.Commands.Ls, only: [execute: 1]

  def run(path \\ nil) do
    start()
    fetch(path) |> reach(path)
  end

  defp reach({:ok, output}, _path), do: puts(output)
  defp reach(:error, path), do: hatch(path)

  defp hatch(path) do
    get_env("EL_DAEMON_SPAWN") |> gate(path)
  end

  defp gate("1", path) do
    spawn()
    wait(0, path)
  end

  defp gate(_, path), do: execute(path: path)

  defp wait(n, path) when n >= 10 do
    execute(path: path)
  end

  defp wait(n, path) do
    sleep(50 * (n + 1))
    fetch(path) |> settle(n, path)
  end

  defp settle({:ok, output}, _n, _path), do: puts(output)
  defp settle(:error, n, path), do: wait(n + 1, path)
end
