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
    case Port.open({:spawn_executable, find_claude()}, port_opts(message, folder)) do
      {:error, reason} ->
        Logger.error("Failed to open Claude port: #{inspect(reason)}")
        "ERROR: Could not start Claude"

      port ->
        try do
          response = read_response(port, "")
          response
        after
          catch_close_port(port)
        end
    end
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
      {^port, {:data, data}} ->
        read_response(port, acc <> data)

      {^port, {:exit_status, _status}} ->
        acc |> String.trim()
    after
      30000 ->
        Logger.warning("Claude port timeout")
        acc
    end
  end

  defp find_claude do
    case System.find_executable("claude") do
      nil -> raise "claude executable not found"
      path -> path
    end
  end

  defp catch_close_port(port) do
    try do
      :ok
    catch
      :error, _ -> :ok
    after
      close_port(port)
    end
  end

  defp close_port(port) do
    try do
      Port.close(port)
    rescue
      _ -> :ok
    end
  end
end
