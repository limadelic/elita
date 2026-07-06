defmodule Agent.Session do
  use GenServer
  require Logger
  import GenServer, only: [start_link: 3, call: 3]
  import String, only: [trim: 1]
  import Port, only: [open: 2, close: 1]
  import System, only: [find_executable: 1]
  import Logger, only: [error: 1, warning: 1]
  import Keyword, only: [fetch!: 2, get: 3]

  def start_link(opts) do
    start_link(__MODULE__, opts, [])
  end

  def ask(pid, message) do
    call(pid, {:ask, message}, :infinity)
  end

  def cast(pid, message) do
    GenServer.cast(pid, {:cast, message})
  end

  @impl true
  def init(opts) do
    name = fetch!(opts, :name)
    folder = fetch!(opts, :folder)
    runner = get(opts, :runner, &default_runner/2)
    {:ok, %{name: name, folder: folder, runner: runner}}
  end

  @impl true
  def handle_call({:ask, message}, _from, state) do
    response = state.runner.(message, state.folder)
    {:reply, {:ok, response}, state}
  end

  @impl true
  def handle_cast({:cast, message}, state) do
    state.runner.(message, state.folder)
    {:noreply, state}
  end

  defp default_runner(message, folder) do
    path = find_claude()

    {:spawn_executable, path}
    |> open(port_opts(message, folder))
    |> handle_port()
  end

  defp handle_port({:error, reason}) do
    error("Failed to open Claude port: #{inspect(reason)}")
    "ERROR: Could not start Claude"
  end

  defp handle_port(port) do
    read_response(port, "")
  after
    close_safe(port)
  end

  defp port_opts(message, folder) do
    [{:args, ["-p", message, "--allowedTools", ""]}, {:cd, String.to_charlist(folder)}] ++
      [:binary, :exit_status, :use_stdio]
  end

  defp read_response(port, acc) do
    receive do
      {^port, msg} -> handle_port_msg(msg, port, acc)
    after
      30000 -> on_timeout(port, acc)
    end
  end

  defp handle_port_msg({:data, data}, port, acc) do
    read_response(port, acc <> data)
  end

  defp handle_port_msg({:exit_status, _}, _port, acc) do
    trim(acc)
  end

  defp on_timeout(port, acc) do
    kill_port_process(port)
    warning("Claude port timeout")
    acc
  end

  defp kill_port_process(port) do
    {:os_pid, pid} = :erlang.port_info(port, :os_pid)
    System.cmd("kill", [to_string(pid)])
  rescue
    _ -> :ok
  end

  defp find_claude do
    find_executable("claude") |> require_executable()
  end

  defp require_executable(nil), do: raise("claude executable not found")
  defp require_executable(path), do: path

  defp close_safe(port) do
    close(port)
  rescue
    _ -> :ok
  end
end
