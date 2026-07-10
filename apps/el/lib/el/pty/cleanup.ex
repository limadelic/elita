defmodule El.Pty.Cleanup do
  @moduledoc false

  import Process, only: [sleep: 1]
  import System, only: [cmd: 2]

  def slay(nil), do: :ok

  def slay(pid) do
    strike(pid)
  rescue
    _ -> :ok
  end

  defp strike(pid) do
    signal(pid, "-TERM")
    sleep(100)
    signal(pid, "-9")
    :ok
  end

  defp signal(pid, sig) do
    cmd("kill", [sig, "-#{pid}"])
  rescue
    _ -> :ok
  end
end
