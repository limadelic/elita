defmodule El.Pty.Cleanup do
  def kill_group(nil), do: :ok
  def kill_group(pgid) do
    signal(pgid, "-TERM")
    Process.sleep(50)
    signal(pgid, "-9")
  rescue
    _ -> :ok
  end

  defp signal(pgid, sig) do
    System.cmd("kill", [sig, "-#{pgid}"])
  rescue
    _ -> :ok
  end
end
