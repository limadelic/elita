defmodule Agent.Session do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def ask(pid, message) do
    GenServer.call(pid, {:ask, message}, :infinity)
  end

  def cast(pid, message) do
    GenServer.cast(pid, {:cast, message})
  end

  @impl true
  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    folder = Keyword.fetch!(opts, :folder)
    runner = Keyword.get(opts, :runner, &default_runner/2)
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
    find_claude()
    |> Port.open(port_opts(message, folder))
    |> handle_port()
  end

  defp handle_port({:error, reason}) do
    Logger.error("Failed to open Claude port: #{inspect(reason)}")
    "ERROR: Could not start Claude"
  end

  defp handle_port(port) do
    read_response(port, "")
  after
    close_safe(port)
  end

  defp port_opts(message, folder) do
    [
      {:args, ["-p", message]},
      {:cd, String.to_charlist(folder)},
      :binary,
      :exit_status,
      :use_stdio,
      :stderr_to_stdout
    ]
  end

  defp read_response(port, acc) do
    receive do
      {^port, {:data, data}} -> read_response(port, acc <> data)
      {^port, {:exit_status, _}} -> String.trim(acc)
    after
      30000 -> Logger.warning("Claude port timeout") || acc
    end
  end

  defp find_claude do
    System.find_executable("claude") || raise "claude executable not found"
  end

  defp close_safe(port) do
    Port.close(port)
  rescue
    _ -> :ok
  end
end
