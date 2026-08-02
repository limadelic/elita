defmodule Agent.Spawn do
  import Application, only: [get_env: 2]
  import Logger, only: [error: 1, warning: 1]
  import Port, only: [open: 2, close: 1]
  import String, only: [trim: 1]
  import System, only: [cmd: 2, find_executable: 1]
  import File, only: [read: 1]

  def run(message, folder, self \\ nil) do
    cmd = {:spawn_executable, exe()}
    open(cmd, setup(message, folder, self)) |> drain()
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

  defp setup(message, folder, self) do
    model = get_env(:elita, :claude_model)
    args = ["-p", message, "--allowedTools", "", "--model", model] ++ prompt(self)
    base = [{:args, args}, {:cd, to_charlist(folder)}]
    base ++ [:binary, :exit_status, :use_stdio]
  end

  defp prompt(nil), do: []
  defp prompt(path), do: inject(read(path), path)

  defp inject({:ok, content}, _path), do: ["--append-system-prompt", content]
  defp inject({:error, _}, _path), do: []

  defp read(port, acc) do
    listen(port, acc)
  end

  defp listen(port, acc) do
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
    cmd("kill", [pid |> to_string()])
  rescue
    _ -> :ok
  end

  defp seal(port) do
    close(port)
  rescue
    _ -> :ok
  end
end
