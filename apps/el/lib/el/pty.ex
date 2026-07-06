defmodule El.Pty do
  use GenServer
  import El.PtyReader, only: [start: 2]
  alias El.Pty.{Cleanup, Size}

  def start_link(name, cmd, opts \\ []) do
    GenServer.start_link(__MODULE__, {cmd, opts}, name: name)
  end

  def inject(name, message) do
    GenServer.cast(name, {:inject, message})
  end

  def run(name, opts \\ []) do
    input = Keyword.get(opts, :input, &identity/1)
    taps = Keyword.get(opts, :taps, [])
    {:ok, pid} = start_link(name, "claude --dangerously-skip-permissions",
      [input: input, taps: taps] ++ Keyword.delete(Keyword.delete(opts, :input), :taps))
    wait_for_exit(pid)
  end

  defp identity(x), do: x

  defp wait_for_exit(pid) do
    ref = Process.monitor(pid)
    receive do
      {:DOWN, ^ref, :process, ^pid, _} -> :ok
    end
  end

  @impl true
  def init({cmd, opts}) do
    file = Keyword.get(opts, :file, :file)
    port = Keyword.get(opts, :port, Port)
    get_size = Keyword.get(opts, :get_size, &default_get_size/0)
    input = Keyword.get(opts, :input, &identity/1)
    taps = Keyword.get(opts, :taps, [])
    {:ok, setup(file, port, cmd, get_size, input, taps)}
  end

  defp setup(file, port, cmd, get_size, input, taps) do
    parent = self()
    pty = open_pty(port, cmd, get_size)
    os_pid = capture_os_pid(port, pty)
    {:ok, tty_out} = file.open("/dev/tty", [:write, :binary, :raw])
    configure_and_start(file, parent)
    monitor_port(pty)
    %{pty: pty, file: file, port: port, tty_out: tty_out, os_pid: os_pid, input: input, taps: taps}
  end

  defp configure_and_start(file, parent) do
    Process.flag(:trap_exit, true)
    spawn_link(fn -> start(file, parent) end)
  end

  defp monitor_port(pty) do
    parent = self()
    Process.spawn(fn -> port_closed_monitor(parent, pty) end, [])
  end

  defp port_closed_monitor(parent, pty) do
    Process.sleep(500)
    unless Port.info(pty) do
      # Port is closed, signal cleanup
      send(parent, {pty, :closed})
    end
  end

  defp capture_os_pid(port, pty) do
    case port.info(pty, :os_pid) do
      {:os_pid, pid} -> pid
      _ -> nil
    end
  end

  defp open_pty(port, cmd, get_size) do
    {rows, cols} = get_size.()
    stty_cmd = "stty rows #{rows} cols #{cols}; stty raw -echo -isig;"
    args = ["-q", "/dev/null", "sh", "-c", "#{stty_cmd} exec #{cmd}"]
    port.open({:spawn_executable, "/usr/bin/script"}, [:binary, :stream, :exit_status, {:args, args}])
  end

  defp default_get_size do
    Size.get_default()
  end

  defp capture_size(%{pty: _pty}) do
    Size.get_default()
  end

  @impl true
  def handle_info({pty, {:data, data}}, %{pty: pty, port: port} = state) do
    file = state.file
    tty_out = state.tty_out
    taps = state.taps
    file.write(tty_out, data)
    notify_taps(taps, data)
    respond_to_dsr(port, pty, data, state)
    {:noreply, state}
  end

  def handle_info({:stdin, data}, %{pty: pty, port: port, input: input} = state) do
    El.Trace.log_chunk(data)
    case input.(data) do
      :drop -> :ok
      transformed -> port.command(pty, transformed)
    end
    {:noreply, state}
  end

  def handle_info({pty, {:exit_status, _}}, %{pty: pty, file: file, tty_out: tty_out, os_pid: os_pid} = state) do
    Cleanup.kill_group(os_pid)
    file.close(tty_out)
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  def handle_info({:EXIT, _pid, reason}, %{os_pid: os_pid} = state) do
    Cleanup.kill_group(os_pid)
    {:stop, reason, state}
  end

  def handle_info({pty, :closed}, %{pty: pty, os_pid: os_pid} = state) do
    Cleanup.kill_group(os_pid)
    {:stop, :normal, state}
  end

  defp notify_taps(taps, data) do
    Enum.each(taps, fn pid -> send(pid, {:output, data}) end)
  end

  defp respond_to_dsr(port, pty, data, state) do
    {rows, cols} = capture_size(state)
    {response, _} = El.Pty.Dsr.scan(data, rows, cols, "")
    if response != "", do: port.command(pty, response)
  end

  @impl true
  def handle_cast({:inject, msg}, %{pty: pty, port: port} = state) do
    El.Trace.log_chunk(msg)
    port.command(pty, msg)
    {:noreply, state}
  end
end
