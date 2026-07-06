defmodule El.Pty.Cleanup do
  @moduledoc false

  def kill_group(nil), do: :ok
  def kill_group(pid) do
    # Kill the process group that the spawned process belongs to
    # Script is the group leader, so killing negative pid kills the group
    signal(pid, "-TERM")
    Process.sleep(100)
    signal(pid, "-9")
    :ok
  rescue
    _ -> :ok
  end

  defp signal(pid, sig) do
    # Kill negative pid to kill the entire process group
    System.cmd("kill", [sig, "-#{pid}"])
  rescue
    _ -> :ok
  end
end
