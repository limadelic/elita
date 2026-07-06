defmodule El.Pty.Cleanup do
  @moduledoc false

  def kill_group(nil), do: :ok
  def kill_group(pid) do
    kill_sequence(pid)
  rescue
    _ -> :ok
  end

  defp kill_sequence(pid) do
    signal(pid, "-TERM")
    Process.sleep(100)
    signal(pid, "-9")
    :ok
  end

  defp signal(pid, sig) do
    System.cmd("kill", [sig, "-#{pid}"])
  rescue
    _ -> :ok
  end
end
