defmodule El.Command.Ls.Boot do
  @moduledoc false
  import System, only: [find_executable: 1]
  import Port, only: [open: 2, close: 1]
  import File, only: [cwd!: 0]

  def spawn do
    find() |> start()
  end

  defp find do
    find_executable("el") |> resolve()
  end

  defp resolve(nil) do
    "#{cwd!()}/../../apps/el/el"
  end

  defp resolve(path), do: path

  defp start(exe) do
    open({:spawn_executable, "/bin/sh"}, opts(exe)) |> close()
  end

  defp opts(exe) do
    [{:args, ["-c", "#{exe} daemon &"]}, :exit_status]
  end
end
