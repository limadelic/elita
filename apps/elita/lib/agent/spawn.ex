defmodule Agent.Spawn do
  import Port, only: [open: 2, close: 1]
  import System, only: [find_executable: 1]
  import Logger, only: [error: 1, warning: 1]
  import String, only: [trim: 1]

  def run(message, folder) do
    cmd = {:spawn_executable, exe()}
    open(cmd, setup(message, folder)) |> drain()
  end

  defp exe do
    find_executable("claude") |> pick()
  end

  defp pick(nil), do: raise("no claude")
  defp pick(path), do: path

  defp drain({:error, reason}) do
    error("Failed to open Claude port: #{inspect(reason)}")
    "ERROR: Could not start Claude"
  end

  defp drain(port) do
    read(port, "")
  after
    seal(port)
  end

  defp setup(message, folder) do
    [{:args, ["-p", message, "--allowedTools", ""]}, {:cd, to_charlist(folder)}] ++
      [:binary, :exit_status, :use_stdio]
  end

  defp read(port, acc) do
    receive do
      {^port, msg} -> recv(msg, port, acc)
    after
      30000 -> stall(port, acc)
    end
  end

  defp recv({:data, data}, port, acc), do: read(port, acc <> data)
  defp recv({:exit_status, _}, _port, acc), do: trim(acc)

  defp stall(port, acc) do
    slay(port)
    warning("Claude port timeout")
    acc
  end

  defp slay(port) do
    {:os_pid, pid} = :erlang.port_info(port, :os_pid)
    System.cmd("kill", [pid |> to_string])
  rescue
    _ -> :ok
  end

  defp seal(port) do
    close(port)
  rescue
    _ -> :ok
  end
end
