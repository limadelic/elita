defmodule Agent.Session do
  use GenServer
  require Logger
  import GenServer, only: [start_link: 3, call: 3]
  import String, only: [trim: 1, downcase: 1]
  import Port, only: [open: 2, close: 1]
  import System, only: [find_executable: 1]
  import Logger, only: [error: 1, warning: 1]
  import Keyword, only: [fetch!: 2, get: 3]

  def start_link(opts) do
    folder = Keyword.fetch!(opts, :folder)
    normalized = Keyword.fetch!(opts, :name) |> to_string |> downcase()
    metadata = %{kind: :headless, folder: folder}
    via_name = {:via, Registry, {ElitaRegistry, normalized, metadata}}
    start_link(__MODULE__, opts, name: via_name)
  end

  def ask(pid, message), do: call(pid, {:ask, message}, :infinity)
  def cast(pid, message), do: GenServer.cast(pid, {:cast, message})
  @impl true
  def init(opts) do
    name = fetch!(opts, :name)
    folder = fetch!(opts, :folder)
    runner = get(opts, :runner, &spawn/2)
    {:ok, %{name: name, folder: folder, runner: runner}}
  end

  @impl true
  def handle_call({:ask, message}, _from, state) do
    response = state.runner.(message, state.folder)
    {:reply, {:ok, response}, state}
  end

  def handle_call({:act, message}, _from, state) do
    response = state.runner.(message, state.folder)
    {:reply, response, state}
  end

  @impl true
  def handle_cast({:cast, message}, state) do
    state.runner.(message, state.folder)
    {:noreply, state}
  end

  defp spawn(message, folder) do
    cmd = {:spawn_executable, exe()}
    open(cmd, setup(message, folder)) |> drain()
  end

  defp exe, do: exec(find_executable("claude"))
  defp exec(nil), do: raise("no claude")
  defp exec(path), do: path

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
    [{:args, ["-p", message, "--allowedTools", ""]}, {:cd, String.to_charlist(folder)}] ++
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
    System.cmd("kill", [to_string(pid)])
  rescue
    _ -> :ok
  end

  defp seal(port) do
    close(port)
  rescue
    _ -> :ok
  end
end
