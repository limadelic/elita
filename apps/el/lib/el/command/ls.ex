defmodule El.Command.Ls do
  @moduledoc false

  import IO, only: [puts: 1]
  import System, only: [get_env: 1]
  import Process, only: [sleep: 1]

  alias El.Commands.Ls
  alias El.Distribution
  alias El.Command.Ls.Query
  alias El.Command.Ls.Boot

  def run(path \\ nil) do
    Distribution.start()
    Query.fetch(path) |> reach(path)
  end

  defp reach({:ok, output}, _path), do: puts(output)
  defp reach(:error, path), do: hatch(path)

  defp hatch(path) do
    get_env("EL_DAEMON_SPAWN") |> gate(path)
  end

  defp gate("1", path) do
    Boot.spawn()
    wait(0, path)
  end

  defp gate(_, path), do: Ls.execute(path: path)

  defp wait(n, path) when n >= 10 do
    Ls.execute(path: path)
  end

  defp wait(n, path) do
    sleep(50 * (n + 1))
    Query.fetch(path) |> settle(n, path)
  end

  defp settle({:ok, output}, _n, _path), do: puts(output)
  defp settle(:error, n, path), do: wait(n + 1, path)
end
