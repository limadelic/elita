defmodule El.Pty.Cleanup do
  def kill_group(nil), do: :ok
  def kill_group(pid) do
    kill_tree(pid, "-TERM")
    Process.sleep(50)
    kill_tree(pid, "-9")
    :ok
  rescue
    _ -> :ok
  end

  defp kill_tree(pid, sig) do
    # Use pgrep to find all descendants and kill them
    System.cmd("pkill", [sig, "-P", to_string(pid)], stderr_to_stdout: true)
    System.cmd("kill", [sig, to_string(pid)], stderr_to_stdout: true)
  rescue
    _ -> :ok
  end
end
