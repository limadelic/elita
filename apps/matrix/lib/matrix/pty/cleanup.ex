defmodule Matrix.Pty.Cleanup do
  @moduledoc false

  import System, only: [cmd: 2]
  import Process, only: [monitor: 1]

  def slay(nil), do: :ok

  def slay(pid) do
    strike(pid)
  rescue
    _ -> :ok
  end

  defp strike(pid) do
    signal(pid, "-TERM")
    await(monitor(pid), pid)
    signal(pid, "-9")
  end

  defp await(ref, pid) do
    receive do
      {:DOWN, ^ref, :process, ^pid, _} -> :ok
    after
      8_000 -> :ok
    end
  end

  defp signal(pid, sig) do
    cmd("kill", [sig, "-#{pid}"])
  rescue
    _ -> :ok
  end
end
